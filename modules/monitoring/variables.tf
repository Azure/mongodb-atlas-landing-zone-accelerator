variable "workspace_id" {
  description = "ID of the Log Analytics workspace to associate with AMPLS."
  type        = string
}

variable "ampls_assoc_name" {
  description = "Name of the AMPLS association."
  type        = string
}

variable "location" {
  description = "Azure region for shared monitoring resources."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to regional resources."
  type        = map(string)
  default     = {}
}

variable "app_insights_name" {
  description = "Name of the Application Insights resource."
  type        = string
  default     = null
}

variable "private_link_scope_name" {
  description = "Name for the Azure Monitor Private Link Scope shared across regions."
  type        = string
}

variable "private_link_scope_resource_group_name" {
  description = "Resource group hosting the shared Azure Monitor Private Link Scope."
  type        = string
}

variable "monitoring_ampls_subnet_id" {
  description = "Subnet ID for the Azure Monitor Private Endpoint."
  type        = string
  default     = null
}

variable "pe_name" {
  description = "Base name for the Azure Monitor private endpoint resources."
  type        = string
  default     = null
}

variable "network_interface_name" {
  description = "Base name for network interfaces created by the monitoring module."
  type        = string
  default     = null
}

variable "private_service_connection_name" {
  description = "Base name for private service connections created by the monitoring module."
  type        = string
  default     = null
}

variable "vnet_id" {
  description = "ID of the virtual network to link monitoring DNS zones."
  type        = string
  default     = null
}

variable "vnet_name" {
  description = "Name of the virtual network to link monitoring DNS zones."
  type        = string
  default     = null
}
