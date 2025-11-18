output "cluster_id" {
  value = module.mongodb_atlas_config.cluster_id
}

output "project_name" {
  value = module.mongodb_atlas_config.project_name
}

output "mongodb_project_id" {
  value = module.mongodb_atlas_config.project_id
}

output "privatelink_ids" {
  value = module.mongodb_atlas_config.privatelink_ids
}

output "atlas_pe_service_ids" {
  value = module.mongodb_atlas_config.atlas_pe_service_ids
}

output "atlas_privatelink_endpoint_ids" {
  value = module.mongodb_atlas_config.atlas_privatelink_endpoint_ids
}

output "vnet_names" {
  value = { for k, m in module.network : k => m.vnet_name }
}

output "regions_values" {
  value = { for k, m in local.regions : k => m }
}

output "function_app_default_hostname" {
  value       = module.observability.observability_function_default_hostname
  description = "The default hostname of the Azure Function App"
}

