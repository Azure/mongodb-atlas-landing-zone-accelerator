output "app_insights_id" {
  value       = azurerm_application_insights.observability.id
  description = "ID of the shared Application Insights instance."
}

output "app_insights_instrumentation_key" {
  value       = azurerm_application_insights.observability.instrumentation_key
  description = "Instrumentation key for the shared Application Insights instance."
  sensitive   = true
}

output "app_insights_connection_string" {
  value       = azurerm_application_insights.observability.connection_string
  description = "Connection string for the shared Application Insights instance."
  sensitive   = true
}

output "ampls_id" {
  value       = azurerm_monitor_private_link_scope.monitoring_pls.id
  description = "ID of the Azure Monitor Private Link Scope."
}

output "ampls_scope_name" {
  value       = var.private_link_scope_name
  description = "Name of the Azure Monitor Private Link Scope used for workspace associations."
}

output "ampls_scope_resource_group_name" {
  value       = var.private_link_scope_resource_group_name
  description = "Resource group containing the Azure Monitor Private Link Scope used for workspace associations."
}

output "private_dns_zone_ids" {
  value = {
    for idx, key in keys(local.monitoring_dns_zone_definitions) :
    key => azurerm_private_dns_zone.monitoring[idx].id
  }
  description = "Private DNS zone IDs linked to the Azure Monitor private endpoint."
}