#Blob EndPoint
resource "azurerm_private_endpoint" "storage_blob" {
  name                          = "pep-${var.pe_name}-blob"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.storage_account_pe_subnet_id
  custom_network_interface_name = "${var.network_interface_name}-blob"

  private_service_connection {
    name                           = "psc-${var.private_service_connection_name}-blob"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.observability_function_storage.id
    subresource_names              = ["blob"]
  }
  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      var.blob_private_dns_zone_id
    ]
  }
}

#Queue EndPoint
resource "azurerm_private_endpoint" "storage_queue" {
  name                          = "pep-${var.pe_name}-queue"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.storage_account_pe_subnet_id
  custom_network_interface_name = "${var.network_interface_name}-queue"

  private_service_connection {
    name                           = "psc-${var.private_service_connection_name}-queue"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.observability_function_storage.id
    subresource_names              = ["queue"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatedns_queue.id]
  }
}

#Table EndPoint
resource "azurerm_private_endpoint" "storage_table" {
  name                          = "pep-${var.pe_name}-table"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.storage_account_pe_subnet_id
  custom_network_interface_name = "${var.network_interface_name}-table"

  private_service_connection {
    name                           = "psc-${var.private_service_connection_name}-table"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.observability_function_storage.id
    subresource_names              = ["table"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatedns_table.id]
  }
}

#File EndPoint
resource "azurerm_private_endpoint" "storage_file" {
  name                          = "pep-${var.pe_name}-file"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.storage_account_pe_subnet_id
  custom_network_interface_name = "${var.network_interface_name}-file"

  private_service_connection {
    name                           = "psc-${var.private_service_connection_name}-file"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.observability_function_storage.id
    subresource_names              = ["file"]
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatedns_file.id]
  }
}

##DNS##
#Storage Account TABLE DNS
resource "azurerm_private_dns_zone" "privatedns_table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "linktovnet_table" {
  name                  = "pdnsz-linkvnet"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.privatedns_table.name
  virtual_network_id    = var.vnet_id
}

#Storage Account QUEUE DNS
resource "azurerm_private_dns_zone" "privatedns_queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "linktovnet_queue" {
  name                  = "pdnsz-linkvnet"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.privatedns_queue.name
  virtual_network_id    = var.vnet_id
}

#Storage Account FILE DNS
resource "azurerm_private_dns_zone" "privatedns_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
}
resource "azurerm_private_dns_zone_virtual_network_link" "linktovnet_file" {
  name                  = "pdnsz-linkvnet"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.privatedns_file.name
  virtual_network_id    = var.vnet_id
}