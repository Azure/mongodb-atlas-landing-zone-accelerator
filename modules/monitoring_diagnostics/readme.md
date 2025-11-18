# Monitoring Diagnostics Module

## Overview

This Terraform module standardizes Azure Monitor diagnostic settings across the solution. It connects supported Azure resources to a centralized Log Analytics workspace (provisioned by the `modules/monitoring` module) so that logs land in the same observability hub. Note: This module captures only log categories and category groups, not metrics.

## Features

- **Consistent Diagnostic Coverage**: Automatically applies diagnostic settings to Function Apps, Key Vaults, Application Insights, Storage sub-services (Blob, Queue, Table, File), and supported network resources (virtual networks).
- **Centralized Log Collection**: Streams all diagnostic log categories to the shared Log Analytics workspace for cross-resource analysis.
- **Flexible Resource Mapping**: Accepts maps of resource IDs so callers can opt into diagnostics per resource or per category.
- **Predictable Naming**: Optional prefix support keeps diagnostic setting names aligned with your environment conventions.
- **Dynamic Category Discovery**: Uses `azurerm_monitor_diagnostic_categories` data source to automatically discover and enable all available log categories for each resource.
- **Idempotent Provisioning**: Terraform-managed settings ensure configuration drift is eliminated across deployments.

## Usage

```hcl
module "monitoring_diagnostics" {
  source = "../../modules/monitoring_diagnostics"

  workspace_id   = module.monitoring.workspace_id
  workspace_name = module.monitoring.workspace_name

  diagnostic_setting_name_prefix = "law-myapp-dev"

  diagnostic_function_app_ids = {
    observability = module.observability.function_app_id
  }

  diagnostic_key_vault_ids = {
    core = module.keyvault.key_vault_id
  }

  diagnostic_storage_blob_service_ids = {
    observability = module.observability.storage_blob_service_id
  }

  diagnostic_storage_queue_service_ids = {
    observability = module.observability.storage_queue_service_id
  }

  diagnostic_storage_table_service_ids = {
    observability = module.observability.storage_table_service_id
  }

  diagnostic_storage_file_service_ids = {
    observability = module.observability.storage_file_service_id
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `workspace_id` | ID of the Log Analytics workspace receiving diagnostics | `string` | - | Yes |
| `workspace_name` | Name of the Log Analytics workspace (used to derive setting names) | `string` | - | Yes |
| `diagnostic_setting_name_prefix` | Base name applied to diagnostic settings | `string` | `null` | No |
| `diagnostic_function_app_ids` | Map of friendly keys to Function App IDs | `map(string)` | `{}` | No |
| `diagnostic_key_vault_ids` | Map of friendly keys to Key Vault IDs | `map(string)` | `{}` | No |
| `diagnostic_storage_blob_service_ids` | Map of friendly keys to Storage Account Blob Service IDs | `map(string)` | `{}` | No |
| `diagnostic_storage_queue_service_ids` | Map of friendly keys to Storage Account Queue Service IDs | `map(string)` | `{}` | No |
| `diagnostic_storage_table_service_ids` | Map of friendly keys to Storage Account Table Service IDs | `map(string)` | `{}` | No |
| `diagnostic_storage_file_service_ids` | Map of friendly keys to Storage Account File Service IDs | `map(string)` | `{}` | No |

## Outputs

This module does not currently export outputs.

## Deployment Order

Deploy this module after both the Log Analytics workspace and the target resources exist:

1. `devops` – foundational resource groups and storage
2. `monitoring` – Log Analytics workspace (diagnostic sink)
3. Resource modules that create assets to be monitored (e.g., `network`, `keyvault`, `observability`, `application`)
4. **`monitoring_diagnostics`** – attach diagnostic settings to the workspace

## Implementation Details

### Dynamic Category Discovery
This module uses the `azurerm_monitor_diagnostic_categories` data source to discover all available log categories for each resource type. It automatically enables all discovered log categories, ensuring comprehensive diagnostic coverage without manual category enumeration. Metrics are intentionally excluded.

### Resource-Specific Behavior
- **App Service Plans**: Diagnostics are not configured as they only emit metrics (logs are not available, and metrics are excluded per requirements).
- **Storage Sub-Services**: Separate diagnostic settings are created for blob, queue, table, and file services with prefixed naming (e.g., `-blob-`, `-queue-`, `-table-`, `-file-`).
- **Subnets & Private Endpoints**: Omitted from diagnostic settings. See implementation comment in `main.tf` for details.

### Conditional Resource Creation
Diagnostic settings are only created when a resource has available log categories. This prevents errors when attempting to configure diagnostics for resources that don't support them or only support metrics.

## Best Practices

### Naming & Organization
- Use the `diagnostic_setting_name_prefix` to align diagnostic setting names with your environment naming standards.
- Group related resources under shared keys (e.g., `core`, `observability`) to simplify future maintenance.
- The module automatically normalizes keys to lowercase and replaces underscores with hyphens for consistent naming.

### Coverage & Maintenance
- Add new resources to their respective maps as soon as they are introduced to keep diagnostics consistent.
- When removing resources, delete them from the corresponding map to allow Terraform to clean up redundant diagnostic settings.
- For Storage Accounts, consider enabling diagnostics for its sub-services (blob, queue, table, file) for complete observability.

### Security & Governance
- Ensure the workspace resides in a secure resource group with restricted access.
- Combine this module with Azure Policy to enforce diagnostic settings on newly created resources.
- Review Log Analytics retention policies (configured in the monitoring module) to meet compliance requirements.
