resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each             = { for k, v in var.subnets : k => v if v != null }
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = (try(each.value.delegation, null) == null) ? [] : [each.value.delegation]
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
  service_endpoints = try(each.value.service_endpoints, [])
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each                  = azurerm_subnet.subnets
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_private_endpoint" "pe" {
  for_each            = var.private_endpoints
  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.subnets[each.value.subnet_key].id
  tags                = try(each.value.tags, var.tags)
  private_service_connection {
    name                           = each.value.service_connection_name
    private_connection_resource_id = each.value.service_resource_id
    is_manual_connection           = each.value.is_manual_connection
    request_message                = try(each.value.request_message, null)
  }
}

resource "mongodbatlas_privatelink_endpoint_service" "endpoint_service" {
  project_id                  = var.project_id
  private_link_id             = var.private_link_id
  endpoint_service_id         = azurerm_private_endpoint.pe[var.mongodb_pe_endpoint_key].id
  private_endpoint_ip_address = azurerm_private_endpoint.pe[var.mongodb_pe_endpoint_key].private_service_connection[0].private_ip_address
  provider_name               = "AZURE"
}