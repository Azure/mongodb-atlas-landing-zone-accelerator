# Monitoring Diagnostics Module

## Overview

This Terraform module standardizes Azure Monitor diagnostic settings across the solution. It connects supported Azure resources to a centralized Log Analytics workspace (one LAW per region in multi region architecture) so that logs land in the same observability hub.

## Features

- **Consistent Diagnostic Coverage**: Automatically applies diagnostic settings to Function Apps, Key Vaults, and Storage sub-services (Blob, Queue, Table, File).
- **Centralized Log Collection**: Streams all diagnostic log categories to the shared Log Analytics workspace for cross-resource analysis.
- **Flexible Resource Mapping**: Accepts maps of resource IDs so callers can opt into diagnostics per resource or per category.
- **Predictable Naming**: Optional prefix support keeps diagnostic setting names aligned with your environment conventions.
- **Dynamic Category Discovery**: Uses `azurerm_monitor_diagnostic_categories` data source to automatically discover and enable all available log categories for each resource.
- **Idempotent Provisioning**: Terraform-managed settings ensure configuration drift is eliminated across deployments.

## Usage

### Example Deployment

```hcl
module "monitoring_diagnostics" {
  source = "../../modules/monitoring_diagnostics"
  for_each = local.regions

  diagnostic_setting_name = module.naming.monitor_diagnostic_setting.name_unique

  diagnostic_targets = {
    workspace_id = azurerm_log_analytics_workspace.regional[each.key].id
    resources = each.value.deploy_observability_function ? {
      function_app_observability  = { id = module.observability_function.function_app_id }
      key_vault_core              = { id = module.kv.key_vault_id }
      storage_blob_observability  = { id = module.observability_function.storage_blob_service_id }
      storage_queue_observability = { id = module.observability_function.storage_queue_service_id }
      storage_table_observability = { id = module.observability_function.storage_table_service_id }
      storage_file_observability  = { id = module.observability_function.storage_file_service_id }
    } : {}
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `diagnostic_setting_name` | Name applied to diagnostic settings | `string` | null | Yes |
| `diagnostic_targets` | Base name applied to diagnostic settings | object({ workspace_id = string, resources = map(object({ id = string}))}) | `null` | Yes |


## Deployment Order

Deploy this module after both the Log Analytics workspace and the target resources exist:

1. `devops` – foundational resource groups and storage
2. `monitoring` – Log Analytics workspace (diagnostic sink)
3. Resource modules that create assets to be monitored (e.g., `network`, `keyvault`, `observability`, `application`)
4. **`monitoring_diagnostics`** – attach diagnostic settings to the workspace

## Implementation Details

### Dynamic Category Discovery
This module uses the `azurerm_monitor_diagnostic_categories` data source to discover all available log categories for each resource type. It automatically enables all discovered log categories, ensuring comprehensive, and probably excessive, diagnostic coverage without manual category enumeration.

### Resource-Specific Behavior
- **Storage Sub-Services**: Separate diagnostic settings are created for blob, queue, table, and file services with prefixed naming (e.g., `-blob-`, `-queue-`, `-table-`, `-file-`).
- **Virtual Networks, Subnets & Private Endpoints**: Omitted from diagnostic settings. See implementation comment in `main.tf` for details.

### Conditional Resource Creation
Diagnostic settings are only created when a resource has available log categories. This prevents errors when attempting to configure diagnostics for resources that don't support them or only support metrics.

### Security & Governance
- Ensure the workspace resides in a secure resource group with restricted access.
- Combine this module with Azure Policy to enforce diagnostic settings on newly created resources.
- Review Log Analytics retention policies (configured in the monitoring module) to meet compliance requirements.
