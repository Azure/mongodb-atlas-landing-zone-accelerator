# Monitoring Regional Module

## Overview
Deploys the observability infrastructure (Azure Monitor Private Link Scope, DNS zones, Private Endpoint, and Application Insights).

## Usage
```hcl
module "monitoring" {
  source   = "../../modules/monitoring"

  workspace_id                           = azurerm_log_analytics_workspace.regional["zoneA"].id
  app_insights_name                      = module.naming.application_insights.name_unique
  location                               = local.regions["zoneA"].location
  private_link_scope_name                = "ampls-${module.naming.log_analytics_workspace.name_unique}"
  private_link_scope_resource_group_name = data.azurerm_resource_group.infrastructure_rgs["zoneA"].name
  monitoring_ampls_subnet_id             = module.network["zoneA"].subnet_ids["private_endpoints"]
  pe_name                                = module.naming.private_endpoint.name_unique
  network_interface_name                 = module.naming.network_interface.name_unique
  private_service_connection_name        = module.naming.private_service_connection.name_unique
  vnet_id                                = module.network["zoneA"].vnet_id
  vnet_name                              = module.network["zoneA"].vnet_name

  tags = local.tags
}
```

## Inputs
| Name | Description | Type | Default | Required |
| --- | --- | --- | --- | --- |
| `workspace_id` | Regional Log Analytics workspace Id | `string` | — | yes |
| `ampls_assoc_name` | AMPLS association name | `string` | — | yes |
| `location` | Azure region for the workspace | `string` | — | yes |
| `app_insights_name` | Application Insights name (used when shared resources are created) | `string` | — | yes |
| `private_link_scope_name` | Name of the Azure Monitor Private Link Scope reused by all regions | `string` | — | yes |
| `private_link_scope_resource_group_name` | Resource group containing the shared Private Link Scope | `string` | — | yes |
| `monitoring_ampls_subnet_id` | Subnet ID used for the Azure Monitor private endpoint (required when the module manages the shared observability resources) | `string` | — | yes |
| `pe_name` | Base name for private endpoint resources | `string` | — | yes |
| `network_interface_name` | Base name for network interfaces | `string` | — | yes |
| `private_service_connection_name` | Base name for private service connections | `string` | — | yes |
| `vnet_id` | Virtual network ID for DNS zone links | `string` | — | yes |
| `vnet_name` | Virtual network name for DNS zone links | `string` | — | yes |
| `tags` | Tags applied to the regional resources | `map(string)` | `{}` | no |

## Outputs
| Name | Description |
|------|-------------|
| `app_insights_id` | ID of the Application Insights instance (null when shared resources are not created) |
| `app_insights_instrumentation_key` | Instrumentation key for Application Insights (sensitive, null when shared resources are not created) |
| `app_insights_connection_string` | Connection string for Application Insights (sensitive, null when shared resources are not created) |
| `ampls_id` | ID of the Azure Monitor Private Link Scope (null when the scope is not created by this module) |
| `ampls_scope_name` | Name of the Azure Monitor Private Link Scope used for workspace associations |
| `ampls_scope_resource_group_name` | Resource group containing the Azure Monitor Private Link Scope |
| `private_dns_zone_ids` | Private DNS zone IDs created for the shared Azure Monitor private endpoint (empty map when not created) |
