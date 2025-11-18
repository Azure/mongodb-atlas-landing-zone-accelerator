# Azure Key Vault Module

## Overview

This Terraform module creates an Azure Key Vault with secure storage for MongoDB Atlas credentials. It implements security best practices including network isolation, private endpoints, and Secure Future Initiative (SFI) alignment.

## Features

- **Secure Secret Storage**: Stores MongoDB Atlas client secret with expiration date and content type metadata
- **Network Security**: Configurable network ACLs to restrict access to specific VNet subnets
- **Private Endpoint**: Secure private connectivity to Key Vault from within the VNet
- **Purge Protection**: Enabled by default to prevent accidental deletion
- **Soft Delete**: 7-day retention for deleted secrets
- **Access Policies**: Built-in access policy for administrators

## Usage

### Basic Example

```hcl
module "keyvault" {
  source = "./modules/keyvault"

  key_vault_name                       = "kv-myapp-prod"
  location                             = "eastus"
  resource_group_name                  = "rg-myapp-prod"
  tenant_id                            = data.azurerm_client_config.current.tenant_id
  admin_object_id                      = data.azurerm_client_config.current.object_id
  mongo_atlas_client_secret            = var.mongo_atlas_client_secret
  mongo_atlas_client_secret_expiration = "2026-01-01T00:00:00Z"
  private_endpoint_subnet_id           = azurerm_subnet.private_endpoints.id
  private_endpoint_name                = "pe-keyvault"
  private_service_connection_name      = "psc-keyvault"
  open_access                          = false
  vnet_id                              = "<vnet-id>"
  vnet_name                            = "<vnet-name>"
  # Optionally override purge protection or soft delete for non-prod:
  # purge_protection_enabled           = false
  # soft_delete_retention_days         = 7
}
```

## Key Vault Purge Protection & Soft Delete Retention

### Usage Guidelines

This module supports configuration of both **purge protection** and **soft delete retention** to balance security with developer flexibility. These are critical for how you manage the lifecycle and recovery of Key Vault resources:

- `purge_protection_enabled` (`bool`):  
  - **Production:** Should be set to `true` (default) for security compliance. When enabled, a deleted Key Vault cannot be purged (permanently deleted) until after the retention period ends.
  - **Development/Testing:** You may set this to `false` to allow immediate, permanent deletion and recreation of Key Vaults with the same name. Be aware this reduces safety against accidental or malicious deletion.

- `soft_delete_retention_days` (`int`, 7–90):  
  - **Production:** Use a longer retention (e.g. 30–90 days) to allow time for recovery from accidental deletions.
  - **Development/Testing:** Shorter values (minimum 7) can improve developer agility and environment re-use.
  - **Important:** Cannot be below 7 or above 90.

> ⚠️ **Implications**  
When purge protection is enabled, you **cannot fully delete or immediately re-create a Key Vault with the same name for the full retention period** (default 7 days). Take this into account for automation, CI/CD, ephemeral environments, and cleanup jobs.

**Example for Development/Testing:**
```hcl
module "keyvault" {
  # ...
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}
```
**Example for Production (recommended):**
```hcl
module "keyvault" {
  # ...
  purge_protection_enabled   = true
  soft_delete_retention_days = 30
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `key_vault_name` | Name of the Azure Key Vault | `string` | - | Yes |
| `location` | Azure region | `string` | - | Yes |
| `resource_group_name` | Name of the Azure resource group | `string` | - | Yes |
| `tenant_id` | Azure Tenant ID | `string` | - | Yes |
| `admin_object_id` | Object ID for the principal to set in Key Vault access policy | `string` | - | Yes |
| `mongo_atlas_client_secret` | The value for the Mongo Atlas client secret | `string` | - | Yes |
| `mongo_atlas_client_secret_expiration` | Expiration date for the secret (ISO 8601 format, e.g. 2026-01-01T00:00:00Z) | `string` | - | Yes |
| `private_endpoint_subnet_id` | Subnet ID for the private endpoint | `string` | - | Yes |
| `private_endpoint_name` | Name for the private endpoint | `string` | - | Yes |
| `private_service_connection_name` | Name for the private service connection | `string` | - | Yes |
| `open_access` | Allow open access during bootstrap? true=Allow, false=Deny for SFI | `bool` | `false` | No |
| `vnet_id` | ID of the Virtual Network to link the Private DNS Zone | `string` | - | yes |
| `vnet_name` | Name of the Virtual Network | `string` | - | yes |
| `purge_protection_enabled` | Enable purge protection for Key Vault? | `bool` | `true` | No |
| `soft_delete_retention_days` | Days for soft delete retention (7-90) | `number` | `7` | No |

## Outputs

| Name | Description |
|------|-------------|
| `key_vault_id` | ID of the Azure Key Vault |
| `mongo_atlas_client_secret_uri` | URI of the MongoDB Atlas client secret in Key Vault (for Key Vault references) |

## Network Access Configuration

The module supports two network access modes via the `open_access` variable:

### Restricted Access (Production - Recommended)
When `open_access = false` (default):
- Network ACL default action is set to **Deny**
- No Azure services can bypass network restrictions (`bypass = "None"`); access is only possible through the configured private endpoint
- Ideal for production environments following zero-trust principles

### Open Access (Development/Testing)
When `open_access = true`:
- Network ACL default action is set to **Allow**
- Public access is permitted
- Useful during initial setup or development
- **Not recommended for production**
