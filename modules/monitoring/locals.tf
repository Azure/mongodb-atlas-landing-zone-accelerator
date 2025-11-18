locals {
  workspace = {
    id                  = azurerm_log_analytics_workspace.central.id
    name                = azurerm_log_analytics_workspace.central.name
    location            = azurerm_log_analytics_workspace.central.location
    resource_group_name = azurerm_log_analytics_workspace.central.resource_group_name
  }
}
