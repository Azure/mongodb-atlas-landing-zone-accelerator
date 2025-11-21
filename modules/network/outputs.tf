output "subnet_ids" {
  value = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "nsg_id" {
  value = { for k, nsg in azurerm_network_security_group.nsg : k => nsg.id }
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "private_endpoint_ids" {
  value = { for k, v in azurerm_private_endpoint.pe : k => v.id }
}