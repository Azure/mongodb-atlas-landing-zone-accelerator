data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "infrastructure_rg" {
  name = data.terraform_remote_state.devops.outputs.resource_group_names.infrastructure["unique"].name
}

module "mongodb_atlas_config" {
  source                   = "../../../../../modules/atlas_config_single_region"
  org_id                   = local.org_id
  cluster_name             = local.cluster_name
  cluster_type             = local.cluster_type
  instance_size            = local.instance_size
  backup_enabled           = local.backup_enabled
  region                   = local.region_definition.atlas_region
  electable_nodes          = local.electable_nodes
  priority                 = local.region_definition.priority
  project_name             = local.project_name
  reference_hour_of_day    = local.reference_hour_of_day
  reference_minute_of_hour = local.reference_minute_of_hour
  restore_window_days      = local.restore_window_days

  providers = {
    mongodbatlas = mongodbatlas
  }
}

module "network" {
  source              = "../../../../../modules/network"
  location            = local.region_definition.azure_region
  resource_group_name = data.azurerm_resource_group.infrastructure_rg.name
  vnet_name           = module.naming.virtual_network.name
  address_space       = local.region_definition.address_space
  nsg_name            = module.naming.network_security_group.name_unique
  tags                = local.tags

  subnets = local.subnets_definitions

  private_endpoints = {
    mongodb = {
      name                    = "${module.naming.private_endpoint.name_unique}-mongodb"
      subnet_key              = "app_workload_subnet_prefixes"
      service_connection_name = "${module.naming.private_service_connection.name}-mongodb"
      service_resource_id     = module.mongodb_atlas_config.atlas_pe_service_id
      is_manual_connection    = local.manual_connection
      request_message         = "Mongo DB Atlas Private Endpoint connection from ${local.project_name}."
      tags                    = local.tags
    }
  }

  project_id              = module.mongodb_atlas_config.project_id
  private_link_id         = module.mongodb_atlas_config.atlas_privatelink_endpoint_id
  mongodb_pe_endpoint_key = "mongodb"

  providers = {
    mongodbatlas = mongodbatlas
  }
}

module "kv" {
  source                               = "../../../../../modules/keyvault"
  resource_group_name                  = data.azurerm_resource_group.infrastructure_rg.name
  location                             = local.region_definition.azure_region
  key_vault_name                       = module.naming.key_vault.name_unique
  tenant_id                            = data.azurerm_client_config.current.tenant_id
  mongo_atlas_client_secret            = local.mongo_atlas_client_secret
  admin_object_id                      = data.azurerm_client_config.current.object_id
  open_access                          = var.open_access
  mongo_atlas_client_secret_expiration = local.mongo_atlas_client_secret_expiration
  private_endpoint_subnet_id           = module.network.subnet_ids["private_endpoints"]
  private_endpoint_name                = "${module.naming.private_endpoint.name_unique}kv"
  private_service_connection_name      = "${module.naming.private_service_connection.name_unique}kv"
  vnet_name                            = module.network.vnet_name
  vnet_id                              = module.network.vnet_id
  purge_protection_enabled             = local.purge_protection_enabled
  soft_delete_retention_days           = local.soft_delete_retention_days
}

# --- Log Analytics Workspace (single region) ---
resource "azurerm_log_analytics_workspace" "regional" {
  name                       = module.naming.log_analytics_workspace.name_unique
  location                   = local.region_definition.azure_region
  resource_group_name        = data.terraform_remote_state.devops.outputs.resource_group_names.infrastructure["unique"].name
  sku                        = local.log_analytics_workspace_sku
  retention_in_days          = local.log_analytics_workspace_retention_in_days
  internet_ingestion_enabled = local.log_analytics_workspace_internet_ingestion_enabled
  internet_query_enabled     = true
  tags                       = local.tags
}

module "monitoring" {
  source = "../../../../../modules/monitoring"

  workspace_id                           = azurerm_log_analytics_workspace.regional.id
  ampls_assoc_name                       = "${azurerm_log_analytics_workspace.regional.name}-ampls-association"
  app_insights_name                      = module.naming.application_insights.name_unique
  location                               = local.region_definition.azure_region
  private_link_scope_name                = "ampls-${module.naming.log_analytics_workspace.name_unique}"
  private_link_scope_resource_group_name = data.azurerm_resource_group.infrastructure_rg.name
  monitoring_ampls_subnet_id             = module.network.subnet_ids["private_endpoints"]
  pe_name                                = module.naming.private_endpoint.name_unique
  network_interface_name                 = module.naming.network_interface.name_unique
  private_service_connection_name        = module.naming.private_service_connection.name_unique
  vnet_id                                = module.network.vnet_id
  vnet_name                              = module.network.vnet_name

  tags = local.tags
}

module "observability_function" {
  source                           = "../../../../../modules/observability_function"
  resource_group_name              = data.azurerm_resource_group.infrastructure_rg.name
  location                         = local.region_definition.azure_region
  function_app_name                = module.naming.function_app.name_unique
  service_plan_name                = module.naming.app_service_plan.name_unique
  storage_account_name             = module.naming.storage_account.name_unique
  app_insights_connection_string   = module.monitoring.app_insights_connection_string
  mongo_atlas_client_id            = local.mongo_atlas_client_id
  mongo_group_name                 = local.project_name
  function_subnet_id               = module.network.subnet_ids["observability_function_app"]
  pe_name                          = module.naming.private_endpoint.name_unique
  network_interface_name           = module.naming.network_interface.name_unique
  private_service_connection_name  = module.naming.private_service_connection.name_unique
  vnet_id                          = module.network.vnet_id
  blob_private_dns_zone_id         = module.monitoring.private_dns_zone_ids["blob"]
  function_frequency_cron          = var.function_frequency_cron
  mongodb_included_metrics         = var.mongodb_included_metrics
  mongodb_excluded_metrics         = var.mongodb_excluded_metrics
  storage_account_pe_subnet_id     = module.network.subnet_ids["private_endpoints"]
  mongo_atlas_client_secret_kv_uri = module.kv.mongo_atlas_client_secret_uri
  open_access                      = var.open_access
  tags                             = local.tags
}

resource "azurerm_role_assignment" "function_app_kv_rbac" {
  scope                = module.kv.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.observability_function.function_app_identity_principal_id
}

module "monitoring_diagnostics" {
  source = "../../../../../modules/monitoring_diagnostics"

  diagnostic_setting_name = module.naming.monitor_diagnostic_setting.name_unique
  diagnostic_targets = {
    workspace_id = azurerm_log_analytics_workspace.regional.id
    resources = {
      function_app_observability  = { id = module.observability_function.function_app_id }
      key_vault_core              = { id = module.kv.key_vault_id }
      storage_blob_observability  = { id = module.observability_function.storage_blob_service_id }
      storage_queue_observability = { id = module.observability_function.storage_queue_service_id }
      storage_table_observability = { id = module.observability_function.storage_table_service_id }
      storage_file_observability  = { id = module.observability_function.storage_file_service_id }
    }
  }

  depends_on = [
    module.monitoring,
    module.network,
    module.observability_function,
    module.kv
  ]
}
