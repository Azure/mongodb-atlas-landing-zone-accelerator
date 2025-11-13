variable "subnets" {
  description = "Map of subnet configurations. Keys are static subnet IDs; values contain name, address_prefixes, delegation, service_endpoints."
  type = map(object({
    name             = string
    address_prefixes = list(string)
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
    service_endpoints = optional(list(string))
  }))
}

variable "nsg_name" {
  description = "Name of the Network Security Group"
  type        = string
}

variable "location" {
  description = "Azure location for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
}

variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
}

variable "address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "private_endpoints" {
  description = "Map of private endpoint objects. Only set for the subnets that need them."
  type = map(object({
    name                    = string
    subnet_key              = string
    service_connection_name = string
    service_resource_id     = string
    is_manual_connection    = bool
    group_ids               = optional(list(string))
    request_message         = optional(string)
    tags                    = optional(map(string))
  }))
  default = {}
}

variable "project_id" {
  description = "MongoDB Atlas project id"
  type        = string
}

variable "private_link_id" {
  description = "MongoDB Atlas private link id"
  type        = string
}

variable "mongodb_pe_endpoint_key" {
  description = "The key in private_endpoints map for the MongoDB endpoint"
  type        = string
}