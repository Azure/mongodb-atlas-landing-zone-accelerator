# Monitoring Module

## Overview

This Terraform module provisions centralized monitoring infrastructure for Azure resources. It creates a Log Analytics workspace that serves as the central data sink for Azure Diagnostics, Application Insights, and other monitoring data across the entire solution.

## Resources Created

- **Log Analytics Workspace**: Central data repository for all monitoring and diagnostic data
- **Application Insights**: Application performance monitoring linked to Log Analytics
- **Azure Monitor Private Link Scope (AMPLS)**: Enables private connectivity to Azure Monitor services
- **Private Endpoint**: Secure private access to AMPLS (Log Analytics + App Insights)
- **Private DNS Zones (4)**: DNS resolution for private monitoring endpoints (oms, ods, monitor, agentsvc)
- **Diagnostic Settings**: Self-monitoring for Log Analytics Workspace and Application Insights

## Features

- **Centralized Log Analytics Workspace**: Single data repository for all monitoring and diagnostic data across modules
- **Cross-Resource Queries**: Enable correlation of logs and metrics across different Azure services
- **Multi-Region Support**: Optional private DNS zone sharing across regions for consistent monitoring infrastructure
- **Flexible Configuration**: Configurable SKU, retention, and network access settings
- **Private Access Support**: Azure Monitor Private Link Scope (AMPLS) for secure data ingestion and querying
- **Cost Optimization**: Consolidated ingestion for better pricing tiers and reduced complexity

## Usage

### Single-Region Deployment

```hcl
module "monitoring" {
  source                          = "./modules/monitoring"
  workspace_name                  = "law-myapp-dev"
  location                        = "eastus"
  resource_group_name             = azurerm_resource_group.example.name
  app_insights_name               = "appi-myapp-dev"
  private_link_scope_name         = "ampls-myapp-dev"
  vnet_id                         = module.network.vnet_id
  vnet_name                       = module.network.vnet_name
  ampls_pe_subnet_id              = module.network.subnet_ids["monitoring_ampls"]
  pe_name                         = "pep-monitoring"
  network_interface_name          = "nic-monitoring"
  private_service_connection_name = "psc-monitoring"
  
  # Optional: customize workspace settings
  sku                        = "PerGB2018"
  retention_in_days          = 30
  internet_ingestion_enabled = false
  internet_query_enabled     = true
  
  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

### Multi-Region Deployment

```hcl
# First region: creates private DNS zones
module "monitoring_zonea" {
  source                          = "./modules/monitoring"
  workspace_name                  = "law-myapp-dev-zonea"
  location                        = "eastus"
  resource_group_name             = azurerm_resource_group.example.name
  app_insights_name               = "appi-myapp-dev-zonea"
  private_link_scope_name         = "ampls-myapp-dev-zonea"
  vnet_id                         = module.network_zonea.vnet_id
  vnet_name                       = module.network_zonea.vnet_name
  enable_ampls_pe                 = true
  ampls_pe_subnet_id              = module.network_zonea.subnet_ids["monitoring_ampls"]
  pe_name                         = "pep-monitoring-zonea"
  network_interface_name          = "nic-monitoring-zonea"
  private_service_connection_name = "psc-monitoring-zonea"
  
  # Create DNS zones in first region
  create_private_dns_zones = true
  
  tags = local.tags
}

# Second region: reuses DNS zones from first region
module "monitoring_zoneb" {
  source                          = "./modules/monitoring"
  workspace_name                  = "law-myapp-dev-zoneb"
  location                        = "westus"
  resource_group_name             = azurerm_resource_group.example.name
  app_insights_name               = "appi-myapp-dev-zoneb"
  private_link_scope_name         = "ampls-myapp-dev-zoneb"
  vnet_id                         = module.network_zoneb.vnet_id
  vnet_name                       = module.network_zoneb.vnet_name
  enable_ampls_pe                 = false  # No AMPLS PE in this region
  create_app_insights             = false
  create_private_link_scope       = false
  
  # Reuse DNS zones from first region
  create_private_dns_zones = false
  private_dns_zone_ids     = module.monitoring_zonea.private_dns_zone_ids
  
  tags = local.tags
}
```

### Integration with Other Modules

```hcl
# Deploy monitoring first
module "monitoring" {
  source                          = "./modules/monitoring"
  workspace_name                  = "law-myapp-dev"
  location                        = "eastus"
  resource_group_name             = azurerm_resource_group.example.name
  app_insights_name               = "appi-myapp-dev"
  private_link_scope_name         = "ampls-myapp-dev"
  vnet_id                         = module.network.vnet_id
  vnet_name                       = module.network.vnet_name
  ampls_pe_subnet_id              = module.network.subnet_ids["monitoring_ampls"]
  pe_name                         = "pep-monitoring"
  network_interface_name          = "nic-monitoring"
  private_service_connection_name = "psc-monitoring"
  tags                            = local.tags
}

# Reference workspace in observability module
module "observability" {
  source                         = "./modules/observability"
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  # ... other variables
}

# Reference workspace for diagnostic settings
module "monitoring_diagnostics" {
  source         = "./modules/monitoring_diagnostics"
  workspace_id   = module.monitoring.workspace_id
  workspace_name = module.monitoring.workspace_name
  # ... other variables
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `workspace_name` | Name of the Log Analytics workspace | `string` | - | Yes |
| `location` | Azure location for the workspace | `string` | - | Yes |
| `resource_group_name` | Name of the Azure Resource Group | `string` | - | Yes |
| `sku` | SKU for Log Analytics Workspace (PerGB2018, CapacityReservation) | `string` | `"PerGB2018"` | No |
| `retention_in_days` | Retention period in days for Log Analytics Workspace (30-730) | `number` | `30` | No |
| `internet_ingestion_enabled` | Should the workspace allow ingestion over the public internet? | `bool` | `false` | No |
| `internet_query_enabled` | Should the workspace allow queries over the public internet? | `bool` | `true` | No |
| `tags` | Tags to apply to the workspace | `map(string)` | `{}` | No |
| `app_insights_name` | Name of the Application Insights instance | `string` | - | Yes |
| `create_app_insights` | Whether to create the Application Insights resource | `bool` | `true` | No |
| `private_link_scope_name` | Name of the Azure Monitor Private Link Scope | `string` | - | Yes |
| `create_private_link_scope` | Whether to create the Azure Monitor Private Link Scope and related resources | `bool` | `true` | No |
| `vnet_id` | ID of the Virtual Network for private endpoints | `string` | - | Yes |
| `vnet_name` | Name of the Virtual Network for private endpoints | `string` | - | Yes |
| `ampls_pe_subnet_id` | Subnet ID for the Azure Monitor Private Link Scope private endpoint | `string` | - | Conditional (required if enable_ampls_pe is true) |
| `pe_name` | Base name for the Private Endpoint | `string` | - | Conditional (required if enable_ampls_pe is true) |
| `network_interface_name` | Base name for the Network Interface | `string` | - | Conditional (required if enable_ampls_pe is true) |
| `private_service_connection_name` | Base name for the Private Service Connection | `string` | - | Conditional (required if enable_ampls_pe is true) |
| `create_private_dns_zones` | Whether to create the private DNS zones. Set to true for the first region only in multi-region deployments | `bool` | `true` | No |
| `private_dns_zone_ids` | Optional existing private DNS zone IDs (keys: `oms`, `ods`, `monitor`, `agentsvc`, `blob`) to use instead of creating new ones. Required if create_private_dns_zones is false | `map(string)` | `null` | Conditional (required if create_private_dns_zones is false) |
| `enable_ampls_pe` | Whether to enable the Private Endpoint for the Azure Monitor Private Link Scope (only used when `create_private_link_scope` is true) | `bool` | `false` | No |

## Outputs

| Name | Description |
|------|-------------|
| `workspace_id` | ID of the central Log Analytics workspace used for diagnostics |
| `workspace_name` | Name of the central Log Analytics workspace used for diagnostics |
| `workspace_location` | Location of the central Log Analytics workspace used for diagnostics |
| `workspace_resource_group_name` | Resource group name where the Log Analytics workspace resides |
| `app_insights_id` | ID of the Application Insights instance (null if App Insights creation is disabled) |
| `app_insights_instrumentation_key` | Instrumentation Key for Application Insights (sensitive, null if App Insights creation is disabled) |
| `app_insights_connection_string` | Connection String for Application Insights (sensitive, null if App Insights creation is disabled) |
| `ampls_id` | ID of the Azure Monitor Private Link Scope (null if private link scope creation is disabled) |
| `private_dns_zone_ids` | Private DNS zone IDs (oms, ods, monitor, agentsvc, blob) created by this module (null if zones were not created) |

## Deployment Order

This module should be deployed **early in the infrastructure provisioning** sequence:

1. `devops` - Resource groups, storage
2. `network` - Virtual networks, subnets
3. **`monitoring`** ← This module (creates Log Analytics workspace)
4. `keyvault` - Key Vault with diagnostic settings
5. `observability` - App Insights, Function with diagnostic settings
6. `application` - Web Apps with diagnostic settings

## Best Practices

### Workspace Design
- Use **one workspace per environment** (dev, staging, prod) for data isolation
- Co-locate workspace in the **same region** as monitored resources to reduce latency
- Use **private ingestion** (`internet_ingestion_enabled = false`) for production security
- Set appropriate **retention** based on compliance requirements (30-730 days)

### Cost Management
- **PerGB2018 SKU**: Pay-as-you-go pricing, best for most scenarios (~$2.76/GB)
- **Commitment Tiers**: Consider 100GB, 200GB reservations for cost savings at scale
- **Retention**: Default 30 days included, extended retention costs ~$0.12/GB/month
- **Typical Monthly Cost**: $8-52 depending on data volume and retention settings

### Multi-Region Considerations
- Create **one workspace per region** for optimal performance and data residency
- Or use **single workspace** if cross-region latency is acceptable (<100ms) and compliance permits

### Security & Compliance
- Data encrypted at rest and in transit by default
- Supports Azure Private Link for secure data ingestion
- Integrates with Azure Monitor for unified observability
- Supports Azure Policy for governance and compliance
- Network access controls via `internet_ingestion_enabled` and `internet_query_enabled` settings
