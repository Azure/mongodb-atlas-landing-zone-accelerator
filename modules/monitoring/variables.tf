variable "workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "location" {
  description = "Azure location for the workspace"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "sku" {
  description = "SKU for Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Retention period in days for Log Analytics Workspace"
  type        = number
  default     = 30
}

variable "internet_ingestion_enabled" {
  description = "Should the workspace allow ingestion over the public internet?"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the workspace"
  type        = map(string)
  default     = {}
}

variable "internet_query_enabled" {
  description = "Should the workspace allow queries over the public internet?"
  type        = bool
  default     = true
}

variable "app_insights_name" {
  description = "Name for Application Insights instance"
  type        = string
}

variable "private_link_scope_name" {
  description = "Name for the Azure Monitor Private Link Scope"
  type        = string
}

variable "vnet_id" {
  description = "ID of the Virtual Network to link the Private DNS Zones"
  type        = string
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "ampls_pe_subnet_id" {
  description = "ID of the subnet for the AMPLS Private Endpoint"
  type        = string
}

variable "pe_name" {
  description = "Base name for the Private Endpoint"
  type        = string
}

variable "network_interface_name" {
  description = "Base name for the Network Interface"
  type        = string
}

variable "private_service_connection_name" {
  description = "Base name for the Private Service Connection"
  type        = string
}

variable "create_private_dns_zones" {
  description = "Whether to create the private DNS zones. Set to true for the first region only in multi-region deployments."
  type        = bool
  default     = true
}

variable "private_dns_zone_ids" {
  description = "Optional existing private DNS zone IDs to use instead of creating new ones. Map with keys: oms, ods, monitor, agentsvc. Required if create_private_dns_zones is false."
  type        = map(string)
  default     = null
}

variable "enable_ampls_pe" {
  description = "Whether to enable the Private Endpoint for the Azure Monitor Private Link Scope."
  type        = bool
  default     = false

}
