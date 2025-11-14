# Network Module

## Overview

This Terraform module provisions core networking resources in Azure and MongoDB Atlas, including:

## Features

- Virtual Network (VNet)
- Private Subnet
- Network Security Group (NSG)
- Private Endpoint for MongoDB Atlas (with Atlas PrivateLink integration)
- Subnets for observability

## Usage

```hcl
module "network" {
  source = "./modules/network"

  vnet_name                       = "vnet-myapp-dev"
  location                        = "East US"
  resource_group_name             = "rg-myapp-dev"
  address_space                   = ["10.0.0.0/16"]
  private_subnet_name             = "snet-private"
  private_subnet_prefixes         = ["10.0.1.0/24"]
  name_prefix                     = "myapp"
  nsg_name                        = "nsg-myapp"
  private_endpoint_name           = "pe-myapp"
  private_service_connection_name = "psc-myapp"
  manual_connection               = false
  private_connection_resource_id  = "resource-id"
  private_subnet_id               = "subnet-id"
  request_message                 = "Please approve connection"
  project_id                      = "project-id"
  private_link_id                 = "private-link-id"
  deploy_observability_subnets                   = true
  observability_function_app_subnet_name         = "snet-function-app"
  observability_function_app_subnet_prefixes     = ["10.0.0.0/29"]
  observability_private_endpoint_subnet_name     = "snet-private-endpoint"
  observability_private_endpoint_subnet_prefixes = ["10.0.1.0/29"]

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

## Inputs

| Name                        | Description                                               | Type           |
| --------------------------- | --------------------------------------------------------- | -------------- |
| `vnet_name`                 | Name of the virtual network                               | `string`       |
| `location`                  | Azure region for the resources                            | `string`       |
| `resource_group_name`       | Resource group for all resources                          | `string`       |
| `address_space`             | Address space for the VNet                                | `list(string)` |
| `private_subnet_name`       | Name of the private subnet                                | `string`       |
| `private_subnet_prefixes`   | Address prefixes for the private subnet                   | `list(string)` |
| `name_prefix`               | Prefix for naming NSG                                     | `string`       |
| `tags`                      | Tags to apply to all resources                            | `map(string)`  |
| `nsg_name`                  | Name of the network security group                        | `string`       |
| `private_endpoint_name`     | Name of the private endpoint for MongoDB                  | `string`       |
| `private_service_connection_name` | Name of the private service connection              | `string`       |
| `manual_connection`         | Whether approval is required for the private endpoint     | `bool`         |
| `private_connection_resource_id` | Resource ID of the MongoDB Atlas instance            | `string`       |
| `private_subnet_id`         | ID of the private subnet                                  | `string`       |
| `request_message`           | Message for manual connection approval                    | `string`       |
| `project_id`                | ID of the MongoDB Atlas project                           | `string`       |
| `private_link_id`           | Atlas Private Link ID                                     | `any`          |
| `deploy_observability_subnets`                | Should observability subnets be deployed?                           | `bool`       |
| `observability_function_app_subnet_name`                | Observability Function App subnet name                           | `string`       |
| `observability_function_app_subnet_prefixes`                | Address space for the Observability Function App                           | `list(string)`       |
| `observability_private_endpoint_subnet_name`                | Observability Private endpoint subnet name                           | `string`       |
| `observability_private_endpoint_subnet_prefixes`                | Address space for the Observability Private endpoint                           | `list(string)`       |

## Outputs

- **vnet\_id**: ID of the Virtual Network.
- **vnet\_name**: Name of the Virtual Network.
- **private\_subnet\_id**: ID of the private subnet.
- **private\_subnet\_nsg\_id**: ID of the NSG associated with the subnet.
- **private\_endpoint\_id**: ID of the MongoDB private endpoint.
- **observability\_function\_app\_subnet\_id**: ID of the Function App subnet.
- **observability\_private\_endpoint\_subnet\_id**: ID of the Private Endpoint