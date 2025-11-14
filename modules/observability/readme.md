# Observability Module

This Terraform module provisions observability infrastructure for monitoring MongoDB Atlas metrics in Azure. It creates all necessary resources to host a scheduled metrics collection Function App.

## Resources Created

- **Azure Application Insights**: Centralized monitoring and diagnostics for metrics collected from MongoDB Atlas.
- **Azure Storage Account & Container**: Secure storage for Function App code and logs (TLS 1.2 enforced, no public nested items, blob retention policy).
- **Azure Service Plan**: Linux Flex Consumption plan for hosting the Function App.
- **Azure Function App (Flex Consumption)**: Hosts the metrics collection function (code must be deployed separately).
- **Private DNS Zones & Links**: Ensures secure, private connectivity for monitoring and storage endpoints.
- **Azure Monitor Private Link Scope & Scoped Service**: Enables private connectivity for Application Insights.
- **Private Endpoint**: Secure private access to Application Insights.

## Usage


Include this module in your Terraform configuration and provide all required variables:

```hcl
module "observability" {
  source                        = "./modules/observability"
  app_insights_name             = "<your-app-insights-name>"
  log_analytics_workspace_name  = "<your-law-name>"
  location                      = "<azure-region>"
  resource_group_name           = "<resource-group-name>"
  storage_account_name          = "<storage-account-name>"
  service_plan_name             = "<service-plan-name>"
  function_app_name             = "<function-app-name>"
  mongo_atlas_client_id         = "<atlas-client-id>"
  mongo_atlas_client_secret     = "<atlas-client-secret>"
  mongo_group_name              = "<atlas-group-name>"
  function_subnet_id            = "<subnet-id>"
  private_link_scope_name       = "<private-link-scope-name>"
  appinsights_assoc_name        = "<appinsights-assoc-name>"
  pe_name                       = "<private-endpoint-name>"
  network_interface_name        = "<network-interface-name>"
  private_service_connection_name = "<private-service-connection-name>"
  vnet_id                       = "<vnet-id>"
  vnet_name                     = "<vnet-name>"
  private_endpoint_subnet_id    = "<private-endpoint-subnet-id>"
  function_frequency_cron       = "<cron-expression>"
  mongodb_included_metrics      = "<comma-separated-metrics>"
  mongodb_excluded_metrics      = "<comma-separated-metrics>"
}
```

## Inputs


| Name                          | Description                                                                 | Type   | Required |
|-------------------------------|-----------------------------------------------------------------------------|--------|----------|
| app_insights_name             | Name for Application Insights                                                | string | yes      |
| log_analytics_workspace_name  | Name for Log Analytics workspace                                             | string | yes      |
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
| function_frequency_cron       | Cron expression for function frequency                                       | string | no      |
| mongodb_included_metrics      | Comma-separated metrics to include for MongoDB monitoring                    | string | no       |
| mongodb_excluded_metrics      | Comma-separated metrics to exclude for MongoDB monitoring                    | string | no       |

## Outputs

| Name                                         | Description                                         |
|----------------------------------------------|-----------------------------------------------------|
| observability_appinsights_instrumentation_key| Instrumentation Key for Application Insights         |
| observability_function_default_hostname      | Default hostname for the observability function app  |

## Security & Best Practices

- Storage account enforces TLS 1.2 and disables public access to nested items.
- Blob retention policy is set for 7 days.
- All containers are private by default.
- Function App uses system-assigned managed identity and runs in a secure subnet.
