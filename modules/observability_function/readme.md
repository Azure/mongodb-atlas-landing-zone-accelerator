# Observability function Module

This Terraform module provisions observability function infrastructure for monitoring MongoDB Atlas metrics in Azure. It creates all necessary resources to host a scheduled metrics collection Function App.

## Resources Created

- **Azure Storage Account & Container**: Secure storage for Function App code and logs (TLS 1.2 enforced, no public nested items, blob retention policy, network rules set to deny by default).
- **Azure Service Plan**: Linux Flex Consumption plan (FC1 SKU) for hosting the Function App.
- **Azure Function App (Flex Consumption)**: Hosts the metrics collection function running .NET 8.0 isolated runtime (code must be deployed separately).
- **Private Endpoints**: Four private endpoints for Storage Account subresources (blob, queue, table, file).
- **Private DNS Zones & Links**: Ensures secure, private connectivity for storage endpoints. The module creates queue, table, and file zones and links, and consumes an existing blob zone managed by the monitoring module.
- **Role Assignments**: System-assigned managed identity with Storage Blob Data Contributor, Storage Account Key Operator Service Role, and Reader and Data Access roles.

## Usage


Include this module in your Terraform configuration and provide all required variables:

```hcl
module "observability_function" {
  source                            = "./modules/observability_function"
  resource_group_name               = "<resource-group-name>"
  location                          = "<azure-region>"
  storage_account_name              = "<storage-account-name>"
  service_plan_name                 = "<service-plan-name>"
  function_app_name                 = "<function-app-name>"
  app_insights_connection_string    = "<app-insights-connection-string>"
  mongo_atlas_client_id             = "<atlas-client-id>"
  mongo_group_name                  = "<atlas-group-name>"
  mongo_atlas_client_secret_kv_uri  = "<secret-kv-uri>"
  function_subnet_id                = "<subnet-id>"
  storage_account_pe_subnet_id      = "<subnet-id>"
  vnet_id                           = "<vnet-id>"
  blob_private_dns_zone_id          = "<blob-private-dns-zone-id>"
  pe_name                           = "<private-endpoint-name>"
  network_interface_name            = "<network-interface-name>"
  private_service_connection_name   = "<private-service-connection-name>"
  function_frequency_cron           = "<cron-expression>"
  
  # Optional parameters
  mongodb_included_metrics          = "<comma-separated-metrics>"  # Default: ""
  mongodb_excluded_metrics          = "<comma-separated-metrics>"  # Default: ""
  open_access                       = false                        # Default: false
}
```

## Inputs

| Name                             | Description                                                                                     | Type   | Required | Default |
| -------------------------------- | ----------------------------------------------------------------------------------------------- | ------ | -------- | ------- |
| resource_group_name              | Name of the Azure Resource Group                                                                | string | yes      | -       |
| location                         | Azure region for resources                                                                      | string | yes      | -       |
| storage_account_name             | Name for the storage account                                                                    | string | yes      | -       |
| service_plan_name                | Name for the service plan                                                                       | string | yes      | -       |
| function_app_name                | Name of the Azure Function App                                                                  | string | yes      | -       |
| app_insights_connection_string   | Connection string for Application Insights (from monitoring module)                             | string | yes      | -       |
| mongo_atlas_client_id            | MongoDB Atlas Public API Key                                                                    | string | yes      | -       |
| mongo_group_name                 | MongoDB Atlas Group/Project Name                                                                | string | yes      | -       |
| mongo_atlas_client_secret_kv_uri | Key Vault Secret URI for Mongo Atlas client secret                                              | string | yes      | -       |
| function_subnet_id               | ID of the subnet to connect the Function App                                                    | string | yes      | -       |
| storage_account_pe_subnet_id     | ID of the subnet for the Storage Account Private Endpoints                                      | string | yes      | -       |
| vnet_id                          | ID of the Virtual Network to link the Private DNS Zones                                         | string | yes      | -       |
| blob_private_dns_zone_id         | Resource ID of the shared `privatelink.blob.core.windows.net` DNS zone (provided by monitoring) | string | yes      | -       |
| pe_name                          | General name for the Private Endpoints                                                          | string | yes      | -       |
| network_interface_name           | General name for the Network Interfaces                                                         | string | yes      | -       |
| private_service_connection_name  | General name for the Private Service Connections                                                | string | yes      | -       |
| function_frequency_cron          | Cron expression for function frequency                                                          | string | yes      | -       |
| mongodb_included_metrics         | Comma-separated metrics to include for MongoDB monitoring. If set, excluded metrics are ignored | string | no       | ""      |
| mongodb_excluded_metrics         | Comma-separated metrics to exclude for MongoDB monitoring                                       | string | no       | ""      |
| open_access                      | Allow public network access during bootstrap? true=Yes, false=No for SFI                        | bool   | no       | false   |

> **Prerequisite**: The monitoring module must supply the Application Insights connection string through `app_insights_connection_string`.

## Outputs

| Name                                    | Description                                                      |
| --------------------------------------- | ---------------------------------------------------------------- |
| observability_function_default_hostname | Default hostname for the observability function app              |
| function_app_identity_principal_id      | Principal ID of the function app's managed identity              |
| storage_account_id                      | ID of the storage account backing the observability function app |
| function_app_id                         | ID of the observability function app                             |
| app_service_plan_id                     | ID of the service plan hosting the observability function app    |
| storage_blob_service_id                 | ID of the Storage Account Blob Service                           |
| storage_queue_service_id                | ID of the Storage Account Queue Service                          |
| storage_table_service_id                | ID of the Storage Account Table Service                          |
| storage_file_service_id                 | ID of the Storage Account File Service                           |

## Security & Best Practices

- **Storage Account Security**:
  - Enforces TLS 1.2 minimum version
  - Disables public access to nested items (`allow_nested_items_to_be_public = false`)
  - Network rules set to deny by default
  - Blob retention policy set for 7 days
  - All containers are private by default
  - Uses StorageAccountConnectionString authentication (due to Terraform provider limitation - see note below)

- **Function App Security**:
  - Uses system-assigned managed identity with three role assignments:
    - Storage Blob Data Contributor
    - Storage Account Key Operator Service Role
    - Reader and Data Access
  - Runs in a secure subnet with VNet integration (`vnet_route_all_enabled = true`)
  - Uses .NET 8.0 isolated runtime
  - MongoDB Atlas client secret securely referenced from Key Vault via URI
  - 2048 MB instance memory

- **Private Networking**:
  - Four private endpoints for storage subresources (blob, queue, table, file)
  - Private DNS zones for queue, table, and file are created automatically; the blob endpoint links to the shared zone created by the monitoring module via `blob_private_dns_zone_id`

- **Known Limitation**: Due to a [Terraform provider bug](https://github.com/hashicorp/terraform-provider-azurerm/issues/30732), the module uses `StorageAccountConnectionString` authentication instead of managed identity. In production, consider implementing proper authentication using Entra ID and disable key-based access on the Storage account once the provider issue is resolved.

## Network Access Configuration

The module supports two network access modes via the `open_access` variable:

### Restricted Access (Production - Recommended)
When `open_access = false` (default):
- `public_network_access_enabled` is set to **false**
- Ideal for production environments following zero-trust principles
- All access must go through private endpoints

### Open Access (Development/Testing)
When `open_access = true`:
- `public_network_access_enabled` is set to **true**
- Public access is permitted, allowing users to deploy Azure Functions code directly
- Useful during initial setup or development
- **Not recommended for production**
