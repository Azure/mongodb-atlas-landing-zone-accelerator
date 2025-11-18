data "azurerm_client_config" "current" {}
module "mongodb_atlas_config" {
  source                   = "../../../../../modules/atlas_config_single_region"
  org_id                   = local.org_id
  cluster_name             = local.cluster_name
  cluster_type             = local.cluster_type
  instance_size            = local.instance_size
  backup_enabled           = local.backup_enabled
  region                   = local.region
  electable_nodes          = local.electable_nodes
  priority                 = local.priority
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
  location            = local.location
  resource_group_name = data.azurerm_resource_group.infrastructure_rg.name
  vnet_name           = module.naming.virtual_network.name
  address_space       = local.vnet_address_space
  nsg_name            = module.naming.network_security_group.name_unique
  tags                = local.tags

  subnets = {
    private = {
      name             = local.private_subnet_name
      address_prefixes = local.private_subnet_prefixes
    }
    observability_function_app = {
      name             = local.observability_function_app_subnet_name
      address_prefixes = local.observability_function_app_subnet_prefixes
      delegation = {
        name = "functionapp-delegation"
        service_delegation = {
          name    = "Microsoft.App/environments"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
    monitoring_ampls = {
      name             = local.monitoring_ampls_subnet_name
      address_prefixes = local.monitoring_ampls_subnet_prefixes
    }
    observability_storage_account = {
      name             = local.observability_storage_account_subnet_name
      address_prefixes = local.observability_storage_account_subnet_prefixes
    }
    keyvault_private_endpoint = {
      name              = local.keyvault_private_endpoint_subnet_name
      address_prefixes  = local.keyvault_private_endpoint_subnet_prefixes
      service_endpoints = ["Microsoft.KeyVault"]
    }
  }


  private_endpoints = {
    mongodb = {
      name                    = "${module.naming.private_endpoint.name_unique}-mongodb"
      subnet_key              = "private"
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

module "monitoring" {
  source                          = "../../../../../modules/monitoring"
  workspace_name                  = module.naming.log_analytics_workspace.name_unique
  location                        = local.location
  resource_group_name             = data.azurerm_resource_group.infrastructure_rg.name
  sku                             = local.log_analytics_workspace_sku
  retention_in_days               = local.log_analytics_workspace_retention_in_days
  internet_ingestion_enabled      = local.log_analytics_workspace_internet_ingestion_enabled
  internet_query_enabled          = true
  app_insights_name               = module.naming.application_insights.name_unique
  private_link_scope_name         = "ampls-${module.naming.log_analytics_workspace.name_unique}"
  vnet_id                         = module.network.vnet_id
  vnet_name                       = module.network.vnet_name
  ampls_pe_subnet_id              = module.network.subnet_ids["monitoring_ampls"]
  pe_name                         = module.naming.private_endpoint.name_unique
  network_interface_name          = module.naming.network_interface.name_unique
  private_service_connection_name = module.naming.private_service_connection.name_unique
  tags                            = local.tags
}

module "kv" {
  source                               = "../../../../../modules/keyvault"
  resource_group_name                  = data.azurerm_resource_group.infrastructure_rg.name
  location                             = local.location
  key_vault_name                       = module.naming.key_vault.name_unique
  tenant_id                            = data.azurerm_client_config.current.tenant_id
  mongo_atlas_client_secret            = local.mongo_atlas_client_secret
  admin_object_id                      = data.azurerm_client_config.current.object_id
  open_access                          = var.open_access
  mongo_atlas_client_secret_expiration = local.mongo_atlas_client_secret_expiration
  private_endpoint_subnet_id           = module.network.subnet_ids["keyvault_private_endpoint"]
  private_endpoint_name                = "${module.naming.private_endpoint.name_unique}kv"
  private_service_connection_name      = "${module.naming.private_service_connection.name_unique}kv"
  vnet_name                            = module.network.vnet_name
  vnet_id                              = module.network.vnet_id
  purge_protection_enabled             = local.purge_protection_enabled
  soft_delete_retention_days           = local.soft_delete_retention_days
}

module "observability" {
  source                           = "../../../../../modules/observability"
  resource_group_name              = data.azurerm_resource_group.infrastructure_rg.name
  location                         = local.location
  log_analytics_workspace_id       = module.monitoring.workspace_id
  app_insights_connection_string   = module.monitoring.app_insights_connection_string
  function_app_name                = module.naming.function_app.name_unique
  service_plan_name                = module.naming.app_service_plan.name_unique
  storage_account_name             = module.naming.storage_account.name_unique
  mongo_atlas_client_id            = local.mongo_atlas_client_id
  mongo_group_name                 = local.project_name
  function_subnet_id               = module.network.subnet_ids["observability_function_app"]
  pe_name                          = module.naming.private_endpoint.name_unique
  network_interface_name           = module.naming.network_interface.name_unique
  private_service_connection_name  = module.naming.private_service_connection.name_unique
  vnet_id                          = module.network.vnet_id
  function_frequency_cron          = var.function_frequency_cron
  mongodb_included_metrics         = var.mongodb_included_metrics
  mongodb_excluded_metrics         = var.mongodb_excluded_metrics
  storage_account_pe_subnet_id     = module.network.subnet_ids["observability_storage_account"]
  mongo_atlas_client_secret_kv_uri = module.kv.mongo_atlas_client_secret_uri
  open_access                      = var.open_access

  depends_on = [module.monitoring, module.network]
}

module "monitoring_diagnostics" {
  source = "../../../../../modules/monitoring_diagnostics"

  workspace_id   = module.monitoring.workspace_id
  workspace_name = module.monitoring.workspace_name

  diagnostic_setting_name_prefix = module.naming.monitor_diagnostic_setting.name

  diagnostic_function_app_ids = {
    observability = module.observability.function_app_id
  }

  diagnostic_key_vault_ids = {
    core = module.kv.key_vault_id
  }

  diagnostic_virtual_network_ids = {
    core = module.network.vnet_id
  }

  diagnostic_application_insights_ids = {
    monitoring = module.monitoring.app_insights_id
  }

  diagnostic_storage_blob_service_ids = {
    observability = module.observability.storage_blob_service_id
  }

  diagnostic_storage_queue_service_ids = {
    observability = module.observability.storage_queue_service_id
  }

  diagnostic_storage_table_service_ids = {
    observability = module.observability.storage_table_service_id
  }

  diagnostic_storage_file_service_ids = {
    observability = module.observability.storage_file_service_id
  }
  depends_on = [
    module.monitoring,
    module.network,
    module.observability,
    module.kv
  ]
}

data "azurerm_resource_group" "infrastructure_rg" {
  name = data.terraform_remote_state.devops.outputs.resource_group_names.infrastructure
}

resource "azurerm_key_vault_access_policy" "function_app_kv_policy" {
  key_vault_id       = module.kv.key_vault_id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = module.observability.function_app_identity_principal_id
  secret_permissions = ["Get", "List"]
}
