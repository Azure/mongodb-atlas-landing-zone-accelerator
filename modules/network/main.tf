resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_network_security_group" "nsg" {
  for_each            = { for k, v in var.subnets : k => v if v != null }
  name                = "${var.nsg_name}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = each.value.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      description                = security_rule.value.description
    }

  }

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

  # Azure automatically manages delegation actions; ignore provider drift
  lifecycle {
    ignore_changes = [
      delegation[0].service_delegation[0].actions,
    ]
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each                  = azurerm_subnet.subnets
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
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
