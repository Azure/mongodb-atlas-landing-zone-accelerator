# Network Module

## Overview

This Terraform module provisions core networking resources in Azure and MongoDB Atlas with a flexible, map-based configuration approach for subnets and private endpoints.

## Features

- **Virtual Network (VNet)**: Configurable address space and location
- **Dynamic Subnets**: Map-based subnet configuration with support for delegations and service endpoints
- **Network Security Group (NSG)**: Pre-configured security rules for inbound and outbound traffic
- **Private Endpoints**: Flexible private endpoint creation for any Azure service
- **MongoDB Atlas PrivateLink Integration**: Automatic configuration of MongoDB Atlas private endpoint service
- **NSG Associations**: Automatic association of NSG with all subnets

## Usage

### Basic Example

```hcl
module "network" {
  source              = "./modules/network"
  vnet_name           = "vnet-myapp-dev"
  location            = "eastus"
  resource_group_name = "rg-myapp-dev"
  address_space       = ["10.0.0.0/26"]
  nsg_name            = "nsg-myapp-dev"

  subnets = {
    private = {
      name             = "snet-mongodb-private"
      address_prefixes = ["10.0.0.0/29"]
      security_rules   = {
        deny_all_inbound = {
          name                       = "DenyAllInbound"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          description                = "Deny all inbound traffic by default."
        }
      }
    }
    function_app = {
      name             = "snet-function-app"
      address_prefixes = ["10.0.0.8/29"]
      delegation = {
        name = "functionapp-delegation"
        service_delegation = {
          name    = "Microsoft.App/environments"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
    observability_pe = {
      name             = "snet-observability-pe"
      address_prefixes = ["10.0.0.16/28"]
    }
    keyvault_pe = {
      name              = "snet-keyvault-pe"
      address_prefixes  = ["10.0.0.48/28"]
      service_endpoints = ["Microsoft.KeyVault"]
    }
  }

  private_endpoints = {
    mongodb = {
      name                    = "pe-mongodb"
      subnet_key              = "private"
      service_connection_name = "psc-mongodb"
      service_resource_id     = module.mongodb_atlas.pe_service_id
      is_manual_connection    = true
      request_message         = "Please approve my MongoDB PE"
      tags = {
        Service = "MongoDB"
      }
    }
  }

  project_id              = module.mongodb_atlas.project_id
  private_link_id         = module.mongodb_atlas.privatelink_endpoint_id
  mongodb_pe_endpoint_key = "mongodb"

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }

  providers = {
    mongodbatlas = mongodbatlas
  }
}
```

## Inputs

| Name                      | Description                                                                                                              | Type                          | Required | Default |
|---------------------------|--------------------------------------------------------------------------------------------------------------------------|-------------------------------|----------|---------|
| `vnet_name`               | Name of the virtual network                                                                                              | `string`                      | Yes      | -       |
| `location`                | Azure region for the resources                                                                                           | `string`                      | Yes      | -       |
| `resource_group_name`     | Resource group for all resources                                                                                         | `string`                      | Yes      | -       |
| `address_space`           | Address space for the VNet                                                                                               | `list(string)`                | Yes      | -       |
| `nsg_name`                | Name of the network security group                                                                                       | `string`                      | Yes      | -       |
| `subnets`                 | Map of subnet configurations with name, address_prefixes, security_rules, optional delegation and service_endpoints      | `map(object)`                 | Yes      | -       |
| `private_endpoints`       | Map of private endpoint configurations                                                                                   | `map(object)`                 | No       | `{}`    |
| `project_id`              | MongoDB Atlas project ID                                                                                                 | `string`                      | Yes      | -       |
| `private_link_id`         | MongoDB Atlas private link ID                                                                                            | `string`                      | Yes      | -       |
| `mongodb_pe_endpoint_key` | The key in private_endpoints map for the MongoDB endpoint                                                                | `string`                      | Yes      | -       |
| `tags`                    | Tags to apply to all resources                                                                                           | `map(string)`                 | No       | `{}`    |

### Subnet Object Structure

Each entry in the `subnets` map should have:

```hcl
{
  name             = string                # Required: Subnet name
  address_prefixes = list(string)          # Required: Address prefixes (e.g., ["10.0.0.0/24"])
  security_rules = map(object({            # Required: Security rules for the NSG
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_address_prefix      = string
    destination_address_prefix = string
    source_port_range          = string
    destination_port_range     = string
    description                = string
  }))
  delegation = optional(object({          # Optional: Subnet delegation
    name = string
    service_delegation = object({
      name    = string                    # e.g., "Microsoft.App/environments"
      actions = list(string)              # e.g., ["Microsoft.Network/virtualNetworks/subnets/action"]
    })
  }))
  service_endpoints = optional(list(string))  # Optional: e.g., ["Microsoft.KeyVault"]
}
```

### Private Endpoint Object Structure

Each entry in the `private_endpoints` map should have:

```hcl
{
  name                    = string                    # Required: Private endpoint name
  subnet_key              = string                    # Required: Key from subnets map
  service_connection_name = string                    # Required: Private service connection name
  service_resource_id     = string                    # Required: Resource ID to connect to
  is_manual_connection    = bool                      # Required: Whether manual approval is needed
  group_ids               = optional(list(string))    # Optional: Subresource names
  request_message         = optional(string)          # Optional: Message for manual approval
  tags                    = optional(map(string))     # Optional: Tags for this endpoint
}
```

## Outputs

| Name                   | Description                                                      |
|------------------------|------------------------------------------------------------------|
| `vnet_id`              | ID of the Virtual Network                                        |
| `vnet_name`            | Name of the Virtual Network                                      |
| `subnet_ids`           | Map of subnet keys to subnet IDs                                 |
| `nsg_id`               | ID of the Network Security Group                                 |
| `private_endpoint_ids` | Map of private endpoint keys to private endpoint IDs             |
