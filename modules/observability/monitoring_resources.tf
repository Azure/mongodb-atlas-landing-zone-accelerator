resource "azurerm_log_analytics_workspace" "law" {
  name                       = var.log_analytics_workspace_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  sku                        = var.log_analytics_workspace_sku
  retention_in_days          = var.log_analytics_workspace_retention_days
  internet_ingestion_enabled = false
}

resource "azurerm_application_insights" "observability_appinsights" {
  name                       = var.app_insights_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  workspace_id               = azurerm_log_analytics_workspace.law.id
  application_type           = "web"
  internet_ingestion_enabled = false
}

resource "azurerm_monitor_private_link_scope" "pls" {
  name                  = var.private_link_scope_name
  resource_group_name   = var.resource_group_name
  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "Open"
}

resource "azurerm_monitor_private_link_scoped_service" "appinsights_assoc" {
  name                = var.appinsights_assoc_name
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.pls.name
  linked_resource_id  = azurerm_application_insights.observability_appinsights.id
}

resource "azurerm_private_dns_zone" "oms" {
  name                = "privatelink.oms.opinsights.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "ods" {
  name                = "privatelink.ods.opinsights.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "monitor" {
  name                = "privatelink.monitor.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "agentsvc" {
  name                = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "oms_link" {
  name                  = "${var.vnet_name}-oms-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.oms.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "ods_link" {
  name                  = "${var.vnet_name}-ods-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.ods.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "monitor_link" {
  name                  = "${var.vnet_name}-monitor-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monitor.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "agentsvc_link" {
  name                  = "${var.vnet_name}-agentsvc-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.agentsvc.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_endpoint" "appinsights_pe" {
  name                          = "${var.pe_name}-ampls"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.ampls_pe_subnet_id
  custom_network_interface_name = "${var.network_interface_name}-ampls"

  private_service_connection {
    name                           = "${var.private_service_connection_name}-ampls"
    private_connection_resource_id = azurerm_monitor_private_link_scope.pls.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.oms.id,
      azurerm_private_dns_zone.ods.id,
      azurerm_private_dns_zone.monitor.id,
      azurerm_private_dns_zone.agentsvc.id,
      azurerm_private_dns_zone.privatedns_blob.id
    ]
  }

  depends_on = [
    azurerm_log_analytics_workspace.law,
    azurerm_application_insights.observability_appinsights,
    azurerm_monitor_private_link_scope.pls,
    azurerm_private_dns_zone.oms,
    azurerm_private_dns_zone.ods,
    azurerm_private_dns_zone.monitor,
    azurerm_private_dns_zone.agentsvc,
    azurerm_private_dns_zone.privatedns_blob,
    azurerm_monitor_private_link_scoped_service.appinsights_assoc
  ]
}
