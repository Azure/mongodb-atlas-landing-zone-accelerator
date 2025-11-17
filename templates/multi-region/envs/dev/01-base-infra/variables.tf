variable "org_id" {
  description = "ID of the MongoDB Atlas organization"
  type        = string
}

variable "cluster_name" {
  description = "Name of MongoDB Atlas cluster"
  type        = string
}

variable "project_name" {
  description = "Name of MongoDB Atlas project"
  type        = string
}

variable "mongo_atlas_client_id" {
  description = "MongoDB Atlas Client ID"
  type        = string
  sensitive   = true
}

variable "mongo_atlas_client_secret" {
  description = "MongoDB Atlas Client Secret"
  type        = string
  sensitive   = true
}

variable "function_frequency_cron" {
  description = "Function frequency in cron format"
  type        = string
  default     = "0 * * * *"
}

variable "resource_group_name_tfstate" {
  description = "Name of Resource Group for TF state"
  type        = string
}

variable "storage_account_name_tfstate" {
  description = "Name of Storage Account for TF state"
  type        = string
}

variable "container_name_tfstate" {
  description = "Name of Container for TF state"
  type        = string
}

variable "key_name_tfstate" {
  description = "Name of Key for devops TF state"
  type        = string
}

variable "mongodb_included_metrics" {
  description = "Metrics to include for MongoDB monitoring. The value has to be a comma-separated string. If this value is set, then excluded metrics are ignored."
  type        = string
  default     = ""
}

variable "mongodb_excluded_metrics" {
  description = "Metrics to exclude for MongoDB monitoring. The value has to be a comma-separated string."
  type        = string
  default     = ""
}

variable "open_access" {
  type        = bool
  description = "If true, Key Vault network ACL and Azure Function will allow all traffic (for bootstrap/dev); if false, will restrict traffic."
  default     = false
}
