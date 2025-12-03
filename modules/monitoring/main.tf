resource "azurerm_monitor_private_link_scope" "monitoring_pls" {
  name                  = var.private_link_scope_name
  resource_group_name   = var.private_link_scope_resource_group_name
  ingestion_access_mode = "PrivateOnly"
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "monitoring" {
  count = length(local.monitoring_dns_zone_definitions)

  name                = values(local.monitoring_dns_zone_definitions)[count.index]
  resource_group_name = var.private_link_scope_resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "monitoring" {
  count = length(local.monitoring_dns_zone_definitions)

  name                  = "${var.vnet_name}-${count.index}-link"
  resource_group_name   = var.private_link_scope_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitoring[count.index].name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "monitoring_ampls_pe" {
  name                          = "pep-${var.pe_name}-ampls"
  location                      = var.location
  resource_group_name           = var.private_link_scope_resource_group_name
  subnet_id                     = var.monitoring_ampls_subnet_id
  custom_network_interface_name = "${var.network_interface_name}-ampls"
  tags                          = var.tags

  private_service_connection {
    name                           = "psc-${var.private_service_connection_name}-ampls"
    private_connection_resource_id = azurerm_monitor_private_link_scope.monitoring_pls.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [for zone in azurerm_private_dns_zone.monitoring : zone.id]
  }

  depends_on = [
    azurerm_monitor_private_link_scoped_service.workspace_assoc,
    azurerm_monitor_private_link_scoped_service.appinsights_assoc
  ]
}

resource "azurerm_application_insights" "observability" {
  name                       = var.app_insights_name
  location                   = var.location
  resource_group_name        = var.private_link_scope_resource_group_name
  workspace_id               = var.workspace_id
  application_type           = "web"
  internet_ingestion_enabled = false
  tags                       = var.tags
}

resource "azurerm_monitor_private_link_scoped_service" "appinsights_assoc" {
  name                = "${var.app_insights_name}-ampls-association"
  resource_group_name = var.private_link_scope_resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.monitoring_pls.name
  linked_resource_id  = azurerm_application_insights.observability.id
}

resource "azurerm_monitor_private_link_scoped_service" "workspace_assoc" {
  name                = var.ampls_assoc_name
  resource_group_name = var.private_link_scope_resource_group_name
  scope_name          = var.private_link_scope_name
  linked_resource_id  = var.workspace_id

  depends_on = [azurerm_monitor_private_link_scope.monitoring_pls]
}
