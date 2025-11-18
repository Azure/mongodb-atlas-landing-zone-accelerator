# Observability Module

This Terraform module provisions observability infrastructure for monitoring MongoDB Atlas metrics in Azure. It creates all necessary resources to host a scheduled metrics collection Function App that sends telemetry to Application Insights (provided by the `monitoring` module).

## Resources Created

- **Azure Storage Account & Container**: Secure storage for Function App code and logs (TLS 1.2 enforced, no public nested items, blob retention policy).
- **Azure Service Plan**: Linux Flex Consumption plan for hosting the Function App.
- **Azure Function App (Flex Consumption)**: Hosts the metrics collection function (code must be deployed separately).
- **Private DNS Zones & Links**: Ensures secure, private connectivity for storage endpoints (blob, queue, table, file).
- **4 Private Endpoints**: Secure private access to Storage Account subresources (blob, queue, table, file).

## Usage


Include this module in your Terraform configuration and provide all required variables:

```hcl
module "observability" {
  source                            = "./modules/observability"
  log_analytics_workspace_id      = "<log-analytics-workspace-id>"
  app_insights_connection_string    = "<app-insights-connection-string>"
  location                          = "<azure-region>"
  resource_group_name               = "<resource-group-name>"
  storage_account_name              = "<storage-account-name>"
  service_plan_name                 = "<service-plan-name>"
  function_app_name                 = "<function-app-name>"
  mongo_atlas_client_id             = "<atlas-client-id>"
  mongo_atlas_client_secret         = "<atlas-client-secret>"
  mongo_group_name                  = "<atlas-group-name>"
  function_subnet_id                = "<subnet-id>"
  private_link_scope_name           = "<private-link-scope-name>"
  appinsights_assoc_name            = "<appinsights-assoc-name>"
  pe_name                           = "<private-endpoint-name>"
  network_interface_name            = "<network-interface-name>"
  private_service_connection_name   = "<private-service-connection-name>"
  vnet_id                           = "<vnet-id>"
  vnet_name                         = "<vnet-name>"
  private_endpoint_subnet_id        = "<private-endpoint-subnet-id>"
  storage_account_pe_subnet_id      = "<subnet-id>"
  mongo_atlas_client_secret_kv_uri  = "<secret-kv-uri>"
  function_frequency_cron           = "<cron-expression>"
  mongodb_included_metrics          = "<comma-separated-metrics>"
  mongodb_excluded_metrics          = "<comma-separated-metrics>"
  open_access                       = <true|false>
}
```

## Inputs


| Name                          | Description                                                                 | Type   | Required |
|-------------------------------|-----------------------------------------------------------------------------|--------|----------|
| log_analytics_workspace_id      | ID of the central Log Analytics workspace for diagnostic settings           | string | yes      |
| app_insights_connection_string  | Connection string for Application Insights (from monitoring module)         | string | yes      |
| location                      | Azure region for resources                                                   | string | yes      |
| resource_group_name           | Resource group name                                                          | string | yes      |
| storage_account_name          | Name for the storage account                                                 | string | yes      |
| service_plan_name             | Name for the service plan                                                    | string | yes      |
| function_app_name             | Name of the Azure Function App                                               | string | yes      |
| mongo_atlas_client_id         | MongoDB Atlas Public API Key                                                 | string | yes      |
| mongo_atlas_client_secret     | MongoDB Atlas Private API Key                                                | string | yes      |
| mongo_group_name              | MongoDB Atlas Group/Project Name                                             | string | yes      |
| function_subnet_id            | ID of the subnet to connect the Function App                                 | string | yes      |
| private_link_scope_name       | Name for the Private Link Scope                                              | string | yes      |
| appinsights_assoc_name        | Name for the App Insights Scoped Resource Association                        | string | yes      |
| pe_name                       | Name for the App Insights Private Endpoint                                   | string | yes      |
| network_interface_name        | Name for the Network Interface created for the Private Endpoint              | string | yes      |
| private_service_connection_name | Name for the Private Endpoint's Private Service Connection                  | string | yes      |
| vnet_id                       | ID of the Virtual Network to link the Private DNS Zone                       | string | yes      |
| vnet_name                     | Name of the Virtual Network                                                  | string | yes      |
| private_endpoint_subnet_id    | ID of the subnet for the Private Endpoint                                    | string | yes      |
| storage_account_pe_subnet_id  | ID of the subnet to connect the Storage account                                 | string | yes      |
| mongo_atlas_client_secret_kv_uri | URI of Keyvault's secret                                 | string | yes      |
| function_frequency_cron       | Cron expression for function frequency                                       | string | no      |
| mongodb_included_metrics      | Comma-separated metrics to include for MongoDB monitoring                    | string | no       |
| mongodb_excluded_metrics      | Comma-separated metrics to exclude for MongoDB monitoring                    | string | no       |
| open_access      |  Azure Function's public network access enabled during bootstrap? true=Yes, false=No for SFI                    | bool | no       |

## Outputs

| Name                                    | Description                                                     |
|-----------------------------------------|-----------------------------------------------------------------|
| observability_function_default_hostname | Default hostname for the observability function app             |
| function_app_identity_principal_id      | Principal ID of the function app's managed identity             |
| storage_account_id                      | ID of the storage account backing the observability function    |
| function_app_id                         | ID of the observability function app                            |
| app_service_plan_id                     | ID of the service plan hosting the observability function app   |

## Security & Best Practices

- Storage account enforces TLS 1.2 and disables public access to nested items.
- Blob retention policy is set for 7 days.
- All containers are private by default.
- Function App uses system-assigned managed identity and runs in a secure subnet.

## Network Access Configuration

The module supports two network access modes via the `open_access` variable:

### Restricted Access (Production - Recommended)
When `open_access = false` (default):
- `public_network_access_enabled` is set to **false**
- Ideal for production environments following zero-trust principles

### Open Access (Development/Testing)
When `open_access = true`:
- `public_network_access_enabled` is set to **true**
- Public access is permitted, so users can deploy the Azure Functions code
- Useful during initial setup or development
- **Not recommended for production**
