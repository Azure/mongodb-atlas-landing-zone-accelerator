output "vnet_name" {
  value = module.network.vnet_name
}

output "cluster_id" {
  value = module.mongodb_atlas_config.cluster_id
}

output "project_name" {
  value = module.mongodb_atlas_config.project_name
}

output "mongodb_project_id" {
  value = module.mongodb_atlas_config.project_id
}
output "privatelink_id" {
  value = module.mongodb_atlas_config.privatelink_id
}

output "atlas_pe_service_id" {
  value = module.mongodb_atlas_config.atlas_pe_service_id
}

output "atlas_privatelink_endpoint_id" {
  value = module.mongodb_atlas_config.atlas_privatelink_endpoint_id
}

output "function_app_default_hostname" {
  value       = module.observability.observability_function_default_hostname
  description = "The default hostname of the Azure Function App"
}

output "log_analytics_workspace_id" {
  value       = module.monitoring.workspace_id
  description = "ID of the central Log Analytics workspace for diagnostic settings"
}

output "log_analytics_workspace_name" {
  value       = module.monitoring.workspace_name
  description = "Name of the central Log Analytics workspace"
}

