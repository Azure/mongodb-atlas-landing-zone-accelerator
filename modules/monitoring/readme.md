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
- **Flexible Configuration**: Configurable SKU, retention, and network access settings
- **Private Access Support**: Private Link for secure data ingestion and querying
- **Cost Optimization**: Consolidated ingestion for better pricing tiers and reduced complexity

## Usage

### Basic Example

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  # Required variables
  workspace_name                  = "law-myapp-prod"
  location                        = "eastus"
  resource_group_name             = "rg-myapp-prod"
  app_insights_name               = "appi-myapp-prod"
  private_link_scope_name         = "ampls-myapp-prod"
  vnet_id                         = azurerm_virtual_network.main.id
  vnet_name                       = azurerm_virtual_network.main.name
  ampls_pe_subnet_id              = azurerm_subnet.monitoring_ampls.id
  pe_name                         = "pe-ampls-myapp"
  network_interface_name          = "nic-ampls-myapp"
  private_service_connection_name = "psc-ampls-myapp"
  
  tags = {
    Environment = "Production"
    Project     = "MyProject"
  }
}
```

### Advanced Example

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  # Required variables
  workspace_name                  = "law-myapp-prod"
  location                        = "eastus"
  resource_group_name             = "rg-myapp-prod"
  app_insights_name               = "appi-myapp-prod"
  private_link_scope_name         = "ampls-myapp-prod"
  vnet_id                         = azurerm_virtual_network.main.id
  vnet_name                       = azurerm_virtual_network.main.name
  ampls_pe_subnet_id              = azurerm_subnet.monitoring_ampls.id
  pe_name                         = "pe-ampls-myapp"
  network_interface_name          = "nic-ampls-myapp"
  private_service_connection_name = "psc-ampls-myapp"
  
  # Optional variables
  sku                        = "PerGB2018"
  retention_in_days          = 90
  internet_ingestion_enabled = false
  internet_query_enabled     = true
  
  tags = {
    Environment = "Production"
    Project     = "MyProject"
    CostCenter  = "Engineering"
  }
}
```

### Integration with Other Modules

```hcl
# Deploy monitoring first
module "monitoring" {
  source                     = "./modules/monitoring"
  workspace_name             = "law-myapp-prod"
  location                   = "eastus"
  resource_group_name        = "rg-myapp-prod"
  sku                        = "PerGB2018"
  retention_in_days          = 30
  internet_ingestion_enabled = false
  tags = {
    Environment = "Production"
  }
}

# Reference workspace in observability module
module "observability" {
  source                     = "./modules/observability"
  log_analytics_workspace_id = module.monitoring.workspace_id
  # ... other variables
}

# Reference workspace for diagnostic settings in other modules
module "keyvault" {
  source                     = "./modules/keyvault"
  log_analytics_workspace_id = module.monitoring.workspace_id
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
| `internet_query_enabled` | Should the workspace allow queries over the public internet? | `bool` | `false` | No |
| `tags` | Tags to apply to the workspace | `map(string)` | `{}` | No |
| `app_insights_name` | Name of the Application Insights instance | `string` | - | Yes |
| `private_link_scope_name` | Name of the Azure Monitor Private Link Scope | `string` | - | Yes |
| `vnet_id` | ID of the Virtual Network for private endpoints | `string` | - | Yes |
| `vnet_name` | Name of the Virtual Network for private endpoints | `string` | - | Yes |
| `ampls_pe_subnet_id` | Subnet ID for the Azure Monitor Private Link Scope private endpoint | `string` | - | Yes |
| `pe_name` | Name of the Private Endpoint | `string` | - | Yes |
| `network_interface_name` | Name of the network interface for the private endpoint | `string` | - | Yes |
| `private_service_connection_name` | Name of the private service connection | `string` | - | Yes |

## Outputs

| Name | Description |
|------|-------------|
| `workspace_id` | ID of the central Log Analytics workspace used for diagnostics |
| `workspace_name` | Name of the central Log Analytics workspace used for diagnostics |
| `workspace_location` | Location of the central Log Analytics workspace used for diagnostics |
| `workspace_resource_group_name` | Resource group name where the Log Analytics workspace resides |
| `app_insights_id` | ID of the Application Insights resource linked to the workspace |
| `app_insights_instrumentation_key` | Instrumentation key for the Application Insights instance (sensitive) |
| `app_insights_connection_string` | Connection string for the Application Insights instance (sensitive) |
| `ampls_id` | ID of the Azure Monitor Private Link Scope (AMPLS) resource |

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
