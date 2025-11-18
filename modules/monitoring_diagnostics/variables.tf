variable "workspace_id" {
  description = "ID of the Log Analytics workspace that will receive diagnostic data."
  type        = string
}

variable "workspace_name" {
  description = "Name of the Log Analytics workspace (used for diagnostic setting defaults)."
  type        = string
}

variable "diagnostic_setting_name_prefix" {
  description = "Optional base name used for diagnostic settings. Defaults to the workspace name."
  type        = string
  default     = null
}

variable "diagnostic_function_app_ids" {
  description = "Map of friendly keys to Function App resource IDs requiring diagnostics."
  type        = map(string)
  default     = {}
}

variable "diagnostic_key_vault_ids" {
  description = "Map of friendly keys to Key Vault resource IDs requiring diagnostics."
  type        = map(string)
  default     = {}
}

variable "diagnostic_virtual_network_ids" {
  description = "Map of friendly keys to Virtual Network resource IDs requiring diagnostics."
  type        = map(string)
  default     = {}
}

variable "diagnostic_application_insights_ids" {
  description = "Map of friendly keys to Application Insights resource IDs requiring diagnostics."
  type        = map(string)
  default     = {}
}

variable "diagnostic_storage_blob_service_ids" {
  description = "Map of friendly keys to Storage Account Blob Service resource IDs requiring diagnostics."
  type        = map(string)
  default     = {}
}

variable "diagnostic_storage_queue_service_ids" {
  description = "Map of friendly keys to Storage Account Queue Service resource IDs requiring diagnostics."
  type        = map(string)
  default     = {}
}

variable "diagnostic_storage_table_service_ids" {
  description = "Map of friendly keys to Storage Account Table Service resource IDs requiring diagnostics."
  type        = map(string)
  default     = {}
}

variable "diagnostic_storage_file_service_ids" {
  description = "Map of friendly keys to Storage Account File Service resource IDs requiring diagnostics."
  type        = map(string)
  default     = {}
}

variable "workspace_ids_by_location" {
  description = "Map of Azure location to Log Analytics Workspace ID for regional routing. If provided, enables regional LAW routing for resources."
  type        = map(string)
  default     = null
}