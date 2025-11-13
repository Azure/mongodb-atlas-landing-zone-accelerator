variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure location for resources"
  type        = string
}

variable "log_analytics_workspace_sku" {
  description = "SKU for Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_workspace_name" {
  description = "Name for Log Analytics Workspace"
  type        = string
}

variable "log_analytics_workspace_retention_days" {
  description = "Retention period in days for Log Analytics Workspace"
  type        = number
  default     = 30
}

variable "app_insights_name" {
  description = "Name for Application Insights instance"
  type        = string
}

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

variable "mongo_atlas_client_id" {
  description = "MongoDB Atlas Public API Key"
  type        = string
  sensitive   = true
}

variable "mongo_group_name" {
  description = "MongoDB Atlas Group/Project Name"
  type        = string
}
variable "function_subnet_id" {
  description = "ID of the subnet to connect the Function App."
  type        = string
}

variable "private_link_scope_name" {
  description = "Name for the Private Link Scope."
  type        = string
}

variable "appinsights_assoc_name" {
  description = "Name for the App Insights Scoped Resource Association."
  type        = string
}

variable "pe_name" {
  description = "Name for the App Insights Private Endpoint."
  type        = string
}

variable "network_interface_name" {
  description = "Name for the Network Interface created for the Private Endpoint."
  type        = string
}

variable "private_service_connection_name" {
  description = "Name for the Private Endpoint's Private Service Connection."
  type        = string

}

variable "vnet_id" {
  description = "ID of the Virtual Network to link the Private DNS Zone."
  type        = string
}

variable "vnet_name" {
  description = "Name of the Virtual Network."
  type        = string
}
variable "private_endpoint_subnet_id" {
  description = "ID of the subnet for the Private Endpoint."
  type        = string
}

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

variable "mongo_atlas_client_secret_kv_uri" {
  description = "Key Vault Secret URI for Mongo Atlas client secret"
  type        = string
}