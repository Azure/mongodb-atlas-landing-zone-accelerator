resource "azurerm_log_analytics_workspace" "central" {
  name                       = var.workspace_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  sku                        = var.sku
  retention_in_days          = var.retention_in_days
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  tags = var.tags
}

# Application Insights for MongoDB metrics collection
resource "azurerm_application_insights" "monitoring_appinsights" {
  name                       = var.app_insights_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  workspace_id               = azurerm_log_analytics_workspace.central.id
  application_type           = "web"
  internet_ingestion_enabled = false

  tags = var.tags
}

# Azure Monitor Private Link Scope for secure monitoring
resource "azurerm_monitor_private_link_scope" "monitoring_pls" {
  name                  = var.private_link_scope_name
  resource_group_name   = var.resource_group_name
  ingestion_access_mode = "PrivateOnly"
  
  tags = var.tags
}

# Link Application Insights to AMPLS
resource "azurerm_monitor_private_link_scoped_service" "appinsights_assoc" {
  name                = "${var.app_insights_name}-ampls-association"
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.monitoring_pls.name
  linked_resource_id  = azurerm_application_insights.monitoring_appinsights.id
}

# Link Log Analytics Workspace to AMPLS
resource "azurerm_monitor_private_link_scoped_service" "workspace_assoc" {
  name                = "${var.workspace_name}-ampls-association"
  resource_group_name = var.resource_group_name
  scope_name          = azurerm_monitor_private_link_scope.monitoring_pls.name
  linked_resource_id  = azurerm_log_analytics_workspace.central.id
}

# Private DNS Zones for Azure Monitor (create only if requested)
resource "azurerm_private_dns_zone" "oms" {
  count = var.create_private_dns_zones ? 1 : 0

  name                = "privatelink.oms.opinsights.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "ods" {
  count = var.create_private_dns_zones ? 1 : 0

  name                = "privatelink.ods.opinsights.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "monitor" {
  count = var.create_private_dns_zones ? 1 : 0

  name                = "privatelink.monitor.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "agentsvc" {
  count = var.create_private_dns_zones ? 1 : 0

  name                = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Local to handle both scenarios: created vs. provided zones
locals {
  dns_zone_ids = var.create_private_dns_zones ? {
    oms      = azurerm_private_dns_zone.oms[0].id
    ods      = azurerm_private_dns_zone.ods[0].id
    monitor  = azurerm_private_dns_zone.monitor[0].id
    agentsvc = azurerm_private_dns_zone.agentsvc[0].id
    } : var.private_dns_zone_ids != null ? var.private_dns_zone_ids : {
    oms      = ""
    ods      = ""
    monitor  = ""
    agentsvc = ""
  }

  # Extract zone names from IDs for linking
  dns_zone_names = {
    oms      = length(split("/", local.dns_zone_ids["oms"])) > 1 ? split("/", local.dns_zone_ids["oms"])[8] : ""
    ods      = length(split("/", local.dns_zone_ids["ods"])) > 1 ? split("/", local.dns_zone_ids["ods"])[8] : ""
    monitor  = length(split("/", local.dns_zone_ids["monitor"])) > 1 ? split("/", local.dns_zone_ids["monitor"])[8] : ""
    agentsvc = length(split("/", local.dns_zone_ids["agentsvc"])) > 1 ? split("/", local.dns_zone_ids["agentsvc"])[8] : ""
  }
}

# Link DNS zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "oms_link" {
  name                  = "${var.vnet_name}-oms-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = local.dns_zone_names["oms"]
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ods_link" {
  name                  = "${var.vnet_name}-ods-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = local.dns_zone_names["ods"]
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "monitor_link" {
  name                  = "${var.vnet_name}-monitor-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = local.dns_zone_names["monitor"]
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "agentsvc_link" {
  name                  = "${var.vnet_name}-agentsvc-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = local.dns_zone_names["agentsvc"]
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

# Private Endpoint for AMPLS
resource "azurerm_private_endpoint" "monitoring_ampls_pe" {
  count = var.enable_ampls_pe ? 1 : 0

  name                          = "${var.pe_name}-ampls"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.ampls_pe_subnet_id
  custom_network_interface_name = "${var.network_interface_name}-ampls"

  private_service_connection {
    name                           = "${var.private_service_connection_name}-ampls"
    private_connection_resource_id = azurerm_monitor_private_link_scope.monitoring_pls.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      local.dns_zone_ids["oms"],
      local.dns_zone_ids["ods"],
      local.dns_zone_ids["monitor"],
      local.dns_zone_ids["agentsvc"]
    ]
  }

  tags = var.tags

  depends_on = [
    azurerm_application_insights.monitoring_appinsights,
    azurerm_log_analytics_workspace.central,
    azurerm_monitor_private_link_scope.monitoring_pls,
    azurerm_monitor_private_link_scoped_service.appinsights_assoc,
    azurerm_monitor_private_link_scoped_service.workspace_assoc,
    azurerm_private_dns_zone_virtual_network_link.oms_link,
    azurerm_private_dns_zone_virtual_network_link.ods_link,
    azurerm_private_dns_zone_virtual_network_link.monitor_link,
    azurerm_private_dns_zone_virtual_network_link.agentsvc_link
  ]
}