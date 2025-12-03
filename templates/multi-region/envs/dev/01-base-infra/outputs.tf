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

output "vnets" {
  value = {
    for k, m in module.network :
    k => {
      name                = m.vnet_name
      resource_group_name = data.azurerm_resource_group.infrastructure_rgs[k].name
    }
  }
}

output "regions_values" {
  value = {
    for k, m in local.regions :
    k => merge(
      m,
      {
        resource_group_name = data.azurerm_resource_group.infrastructure_rgs[k].name
      }
    )
  }
}

output "function_app_default_hostname" {
  value       = module.observability_function.observability_function_default_hostname
  description = "The default hostname of the Azure Function App"
}

