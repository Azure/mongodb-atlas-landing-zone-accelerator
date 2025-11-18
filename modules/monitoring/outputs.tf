output "workspace_id" {
  value       = local.workspace.id
  description = "ID of the central Log Analytics workspace used for diagnostics"
}

output "workspace_name" {
  value       = local.workspace.name
  description = "Name of the central Log Analytics workspace used for diagnostics"
}

output "workspace_location" {
  value       = local.workspace.location
  description = "Location of the central Log Analytics workspace used for diagnostics"
}

output "workspace_resource_group_name" {
  value       = local.workspace.resource_group_name
  description = "Resource group name where the Log Analytics workspace resides"
}

output "app_insights_id" {
  value       = azurerm_application_insights.monitoring_appinsights.id
  description = "ID of the Application Insights instance"
}

output "app_insights_instrumentation_key" {
  value       = azurerm_application_insights.monitoring_appinsights.instrumentation_key
  description = "Instrumentation Key for Application Insights"
  sensitive   = true
}

output "app_insights_connection_string" {
  value       = azurerm_application_insights.monitoring_appinsights.connection_string
  description = "Connection String for Application Insights"
  sensitive   = true
}

output "ampls_id" {
  value       = azurerm_monitor_private_link_scope.monitoring_pls.id
  description = "ID of the Azure Monitor Private Link Scope"
}

output "private_dns_zone_ids" {
  value = var.create_private_dns_zones ? {
    oms      = azurerm_private_dns_zone.oms[0].id
    ods      = azurerm_private_dns_zone.ods[0].id
    monitor  = azurerm_private_dns_zone.monitor[0].id
    agentsvc = azurerm_private_dns_zone.agentsvc[0].id
  } : null
  description = "Private DNS zone IDs created by this module (null if zones were not created)"
}