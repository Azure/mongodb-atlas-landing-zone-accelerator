# VNet Peering Module

## Overview

This Terraform module provisions virtual network peering between two VNets in Azure.

## Features

- Creates peering from this VNet to the peer VNet
- Creates peering from the peer VNet to this VNet

## Usage

```hcl
module "vnet_peering" {
  source = "./modules/vnet_peering"

  name_this_to_peer         = "this-to-peer"
  name_peer_to_this         = "peer-to-this"
  resource_group_name_this  = "rg-this"
  resource_group_name_peer  = "rg-peer"
  vnet_name_this            = "vnet-this"
  vnet_name_peer            = "vnet-peer"
  vnet_id_this              = "vnet-id-this"
  vnet_id_peer              = "vnet-id-peer"

  allow_forwarded_traffic   = false
  allow_gateway_transit     = false
  use_remote_gateways       = false
}
```

## Inputs

| Name                    | Description                                      | Type           |
| ----------------------- | ------------------------------------------------ | -------------- |
| `name_this_to_peer`     | Name of the peering from this VNet to the peer VNet | `string`       |
| `name_peer_to_this`     | Name of the peering from the peer VNet to this VNet | `string`       |
| `resource_group_name_this` | Resource group of the first VNet              | `string`       |
| `resource_group_name_peer` | Resource group of the second VNet             | `string`       |
| `vnet_name_this`        | Name of the first VNet                          | `string`       |
| `vnet_name_peer`        | Name of the second VNet                         | `string`       |
| `vnet_id_this`          | ID of the first VNet                            | `string`       |
| `vnet_id_peer`          | ID of the second VNet                           | `string`       |
| `allow_forwarded_traffic` | Whether to allow forwarded traffic             | `bool`         |
| `allow_gateway_transit` | Whether to allow gateway transit                | `bool`         |
| `use_remote_gateways`   | Whether to use remote gateways                  | `bool`         |

## Outputs

- **peering\_ids**: Contains IDs for both virtual network peerings.
