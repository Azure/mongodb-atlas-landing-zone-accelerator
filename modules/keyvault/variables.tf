variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "open_access" {
  description = "Allow open access during bootstrap? true=Allow, false=Deny for SFI"
  type        = bool
  default     = false
}

variable "virtual_network_subnet_ids" {
  description = "List of subnet IDs permitted access to the Key Vault"
  type        = list(string)
  default     = []
}

variable "admin_object_id" {
  description = "Object ID for the principal to set in Key Vault access policy"
  type        = string
}

variable "mongo_atlas_client_secret" {
  description = "The value for the Mongo Atlas client secret"
  type        = string
  sensitive   = true
}

variable "mongo_atlas_client_secret_expiration" {
  description = "Expiration date for the secret (ISO 8601 format, e.g. 2026-01-01T00:00:00Z)"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
}

variable "private_endpoint_name" {
  description = "Name for the private endpoint"
  type        = string
}

variable "private_service_connection_name" {
  description = "Name for the private service connection"
  type        = string
}

variable "purge_protection_enabled" {
  description = "Whether purge protection is enabled for Key Vault. In production, this should be true."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days that deleted Key Vaults are retained. Must be between 7 and 90."
  type        = number
  default     = 7
}