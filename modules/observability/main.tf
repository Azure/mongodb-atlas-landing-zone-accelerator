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

resource "azurerm_storage_account" "observability_function_storage" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "observability_function_container" {
  name                  = "observability-function"
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.observability_function_storage.id
}

resource "azurerm_service_plan" "observability_function_plan" {
  name                = var.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "FC1"
  os_type             = "Linux"
}

resource "azurerm_function_app_flex_consumption" "observability_function" {
  name                = var.function_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.observability_function_plan.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.observability_function_storage.primary_blob_endpoint}${azurerm_storage_container.observability_function_container.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.observability_function_storage.primary_access_key

  runtime_name           = "dotnet-isolated"
  runtime_version        = "8.0"
  maximum_instance_count = 40
  instance_memory_in_mb  = 2048

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.observability_appinsights.connection_string
    "MONGODB_CLIENT_ID"                     = var.mongo_atlas_client_id
    "MONGODB_CLIENT_SECRET"                 = format("@Microsoft.KeyVault(SecretUri=%s)", var.mongo_atlas_client_secret_kv_uri)
    "MONGODB_GROUP_NAME"                    = var.mongo_group_name
    "AzureWebJobsStorage"                   = azurerm_storage_account.observability_function_storage.primary_connection_string
    "FUNCTION_FREQUENCY_CRON"               = var.function_frequency_cron
    "MONGODB_INCLUDED_METRICS"              = var.mongodb_included_metrics
    "MONGODB_EXCLUDED_METRICS"              = var.mongodb_excluded_metrics
  }

  identity {
    type = "SystemAssigned"
  }

  virtual_network_subnet_id = var.function_subnet_id

  site_config {}
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

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
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

resource "azurerm_private_dns_zone_virtual_network_link" "blob_link" {
  name                  = "${var.vnet_name}-blob-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "agentsvc_link" {
  name                  = "${var.vnet_name}-agentsvc-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.agentsvc.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_endpoint" "appinsights_pe" {
  name                          = var.pe_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = var.private_endpoint_subnet_id
  custom_network_interface_name = var.network_interface_name

  private_service_connection {
    name                           = var.private_service_connection_name
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
      azurerm_private_dns_zone.blob.id
    ]
  }

  depends_on = [
    azurerm_log_analytics_workspace.law,
    azurerm_application_insights.observability_appinsights,
    azurerm_monitor_private_link_scope.pls
  ]
}
