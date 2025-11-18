#General Variables
variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure location for resources"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the central Log Analytics workspace for diagnostic settings"
}
variable "network_interface_name" {
  description = "General name for the Network Interface."
  type        = string
}

variable "pe_name" {
  description = "General name for the Private Endpoint."
  type        = string
}

variable "private_service_connection_name" {
  description = "General name for the Private Service Connections."
  type        = string
}

variable "app_insights_connection_string" {
  description = "Connection string for Application Insights (from monitoring module)"
  type        = string
  sensitive   = true
}

# Function App related variables
variable "function_app_name" {
  description = "Name of the Azure Function App"
  type        = string
}

variable "service_plan_name" {
  description = "Name of the App Service Plan for the Azure Function"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the Storage Account for Azure Function"
  type        = string
}

# VNet related variables

variable "vnet_id" {
  description = "ID of the Virtual Network to link the Private DNS Zone."
  type        = string
}

variable "storage_account_pe_subnet_id" {
  description = "ID of the subnet for the Storage Account Private Endpoints."
  type        = string
}

variable "function_subnet_id" {
  description = "ID of the subnet to connect the Function App."
  type        = string
}

# Function App Setting Variables

variable "function_frequency_cron" {
  description = "Cron expression for function frequency."
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

variable "mongo_atlas_client_id" {
  description = "MongoDB Atlas Public API Key"
  type        = string
  sensitive   = true
}

variable "mongo_group_name" {
  description = "MongoDB Atlas Group/Project Name"
  type        = string
}

variable "mongo_atlas_client_secret_kv_uri" {
  description = "Key Vault Secret URI for Mongo Atlas client secret"
  type        = string
}

variable "maximum_instance_count" {
  description = "Maximum number of instances the function app can scale out to. Minimum is 40, maximum is 1000."
  type        = number
  default     = 40
}

variable "open_access" {
  description = "Allow open access during bootstrap? true=Allow, false=Deny for SFI"
  type        = bool
  default     = false
}
