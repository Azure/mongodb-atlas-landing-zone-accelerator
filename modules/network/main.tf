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

  # Allow traffic originating from inside the VNet to any destination within the VNet
  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    description                = "Allow inbound traffic from within the Virtual Network."
  }

  # Block any inbound traffic coming in from the public Internet
  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    description                = "Deny inbound traffic from the public Internet."
  }

  # Default deny rule for inbound traffic, denies all inbound connections not previously allowed or denied
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    description                = "Deny all other inbound traffic by default."
  }

  # Allow outbound traffic to any resource within the VNet (east-west communication)
  security_rule {
    name                       = "AllowVNetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_range     = "*"
    description                = "Allow outbound traffic to resources within the Virtual Network."
  }

  # Allow outbound UDP traffic to Azure DNS (required for DNS resolution)
  security_rule {
    name                       = "AllowDNS"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureDNS"
    source_port_range          = "*"
    destination_port_range     = "53"
    description                = "Allow outbound UDP traffic to Azure DNS for DNS resolution (port 53)."
  }

  # Allow outbound HTTPS connections to the Internet (for example, to access external APIs such as MongoDB Atlas)
  security_rule {
    name                       = "AllowInternetHTTPS"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
    source_port_range          = "*"
    destination_port_range     = "443"
    description                = "Allow outbound TCP traffic to the Internet on port 443 for secure API calls (e.g., MongoDB Atlas Metris API)."
  }

  # Deny all other outbound traffic not explicitly allowed above
  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    description                = "Deny all other outbound traffic by default."
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
