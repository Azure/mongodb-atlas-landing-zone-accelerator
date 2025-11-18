data "azurerm_client_config" "current" {}
module "mongodb_atlas_config" {
  source                   = "../../../../../modules/atlas_config_multi_region"
  org_id                   = local.org_id
  cluster_name             = local.cluster_name
  cluster_type             = local.cluster_type
  backup_enabled           = local.backup_enabled
  region_configs           = local.region_configs
  project_name             = local.project_name
  reference_hour_of_day    = local.reference_hour_of_day
  reference_minute_of_hour = local.reference_minute_of_hour
  restore_window_days      = local.restore_window_days
  providers = {
    mongodbatlas = mongodbatlas
  }
}

module "network" {
  for_each            = local.regions
  source              = "../../../../../modules/network"
  location            = each.value.location
  resource_group_name = data.azurerm_resource_group.infrastructure_rg.name
  vnet_name           = "${module.naming.virtual_network.name_unique}-${each.key}"
  nsg_name            = "${module.naming.network_security_group.name_unique}-${each.key}"
  address_space       = each.value.address_space
  tags                = local.tags

  subnets = {
    private = {
      name             = each.value.private_subnet_name
      address_prefixes = each.value.private_subnet_prefixes
    }
    observability_function_app = each.value.deploy_observability_subnets ? {
      name             = each.value.observability_function_app_subnet_name
      address_prefixes = each.value.observability_function_app_subnet_prefixes
      delegation = {
        name = "functionapp-delegation"
        service_delegation = {
          name    = "Microsoft.App/environments"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    } : null
    monitoring_ampls = each.value.deploy_observability_subnets ? {
      name             = each.value.monitoring_ampls_subnet_name
      address_prefixes = each.value.monitoring_ampls_subnet_prefixes
    } : null
    keyvault_private_endpoint = each.value.has_keyvault_private_endpoint ? {
      name              = each.value.keyvault_private_endpoint_subnet_name
      address_prefixes  = each.value.keyvault_private_endpoint_subnet_prefixes
      service_endpoints = ["Microsoft.KeyVault"]
    } : null
    observability_storage_account = each.value.has_observability_storage_account ? {
      name             = each.value.observability_storage_account_subnet_name
      address_prefixes = each.value.observability_storage_account_subnet_prefixes
    } : null
  }

  private_endpoints = {
    mongodb = {
      name                    = "${module.naming.private_endpoint.name_unique}-mongodb-${each.key}"
      subnet_key              = "private"
      service_connection_name = "${module.naming.private_service_connection.name}-mongodb-${each.key}"
      service_resource_id     = module.mongodb_atlas_config.atlas_pe_service_ids[each.key]
      is_manual_connection    = each.value.manual_connection
      request_message         = "Please approve my MongoDB PE."
      tags                    = local.tags
    }
  }

  project_id              = module.mongodb_atlas_config.project_id
  private_link_id         = module.mongodb_atlas_config.atlas_privatelink_endpoint_ids[each.key]
  mongodb_pe_endpoint_key = "mongodb"

  providers = {
    mongodbatlas = mongodbatlas
  }
}

module "vnet_peerings" {
  for_each = local.vnet_pairs
  source   = "../../../../../modules/vnet_peering"

  name_this_to_peer = "${each.value.a}-to-${each.value.b}"
  name_peer_to_this = "${each.value.b}-to-${each.value.a}"

  resource_group_name_this = data.azurerm_resource_group.infrastructure_rg.name
  resource_group_name_peer = data.azurerm_resource_group.infrastructure_rg.name

  vnet_name_this = module.network[each.value.a].vnet_name
  vnet_name_peer = module.network[each.value.b].vnet_name
  vnet_id_this   = module.network[each.value.a].vnet_id
  vnet_id_peer   = module.network[each.value.b].vnet_id

  allow_forwarded_traffic = false
  allow_gateway_transit   = false
  use_remote_gateways     = false
}

# Create monitoring infrastructure per region
module "monitoring" {
  for_each = local.regions
  source   = "../../../../../modules/monitoring"

  # Unique names per region
  workspace_name          = "${module.naming.log_analytics_workspace.name_unique}-${each.key}"
  app_insights_name       = "${module.naming.application_insights.name_unique}-${each.key}"
  private_link_scope_name = "ampls-${module.naming.log_analytics_workspace.name_unique}-${each.key}"

  # Regional configuration
  location            = each.value.location
  resource_group_name = data.azurerm_resource_group.infrastructure_rg.name

  # VNet configuration (required for DNS zone links)
  vnet_id   = module.network[each.key].vnet_id
  vnet_name = module.network[each.key].vnet_name

  # AMPLS PE configuration (only for zones with monitoring subnets)
  enable_ampls_pe    = each.value.deploy_observability_subnets
  ampls_pe_subnet_id = each.value.deploy_observability_subnets ? module.network[each.key].subnet_ids["monitoring_ampls"] : null

  # DNS zones: Create in first region (zoneA), reuse in others
  create_private_dns_zones = each.key == "zoneA"
  private_dns_zone_ids     = each.key != "zoneA" ? module.monitoring["zoneA"].private_dns_zone_ids : null

  # PE naming
  pe_name                         = "${module.naming.private_endpoint.name_unique}-${each.key}"
  network_interface_name          = "${module.naming.network_interface.name_unique}-${each.key}"
  private_service_connection_name = "${module.naming.private_service_connection.name_unique}-${each.key}"

  # LAW configuration
  sku                        = local.log_analytics_workspace_sku
  retention_in_days          = local.log_analytics_workspace_retention_in_days
  internet_ingestion_enabled = local.log_analytics_workspace_internet_ingestion_enabled
  internet_query_enabled     = true

  tags = local.tags

  depends_on = [module.network]
}

module "kv" {
  source                               = "../../../../../modules/keyvault"
  resource_group_name                  = data.azurerm_resource_group.infrastructure_rg.name
  location                             = local.regions["zoneA"].location
  key_vault_name                       = module.naming.key_vault.name_unique
  tenant_id                            = data.azurerm_client_config.current.tenant_id
  mongo_atlas_client_secret            = local.mongo_atlas_client_secret
  admin_object_id                      = data.azurerm_client_config.current.object_id
  open_access                          = var.open_access
  mongo_atlas_client_secret_expiration = local.mongo_atlas_client_secret_expiration
  private_endpoint_subnet_id           = module.network["zoneA"].subnet_ids["keyvault_private_endpoint"]
  private_endpoint_name                = "${module.naming.private_endpoint.name_unique}kv"
  private_service_connection_name      = "${module.naming.private_service_connection.name_unique}kv"
  vnet_id                              = module.network["zoneA"].vnet_id
  vnet_name                            = module.network["zoneA"].vnet_name
  purge_protection_enabled             = local.purge_protection_enabled
  soft_delete_retention_days           = local.soft_delete_retention_days
}

module "observability" {
  source                           = "../../../../../modules/observability"
  resource_group_name              = data.azurerm_resource_group.infrastructure_rg.name
  location                         = local.regions["zoneA"].location
  log_analytics_workspace_id       = module.monitoring["zoneA"].workspace_id
  app_insights_connection_string   = module.monitoring["zoneA"].app_insights_connection_string
  function_app_name                = module.naming.function_app.name_unique
  service_plan_name                = module.naming.app_service_plan.name_unique
  storage_account_name             = module.naming.storage_account.name_unique
  mongo_atlas_client_id            = local.mongo_atlas_client_id
  mongo_group_name                 = local.project_name
  function_subnet_id               = module.network["zoneA"].subnet_ids["observability_function_app"]
  pe_name                          = module.naming.private_endpoint.name_unique
  network_interface_name           = module.naming.network_interface.name_unique
  private_service_connection_name  = module.naming.private_service_connection.name_unique
  vnet_id                          = module.network["zoneA"].vnet_id
  function_frequency_cron          = var.function_frequency_cron
  mongodb_included_metrics         = var.mongodb_included_metrics
  mongodb_excluded_metrics         = var.mongodb_excluded_metrics
  storage_account_pe_subnet_id     = module.network["zoneA"].subnet_ids["observability_storage_account"]
  mongo_atlas_client_secret_kv_uri = module.kv.mongo_atlas_client_secret_uri
  open_access                      = var.open_access

  depends_on = [
    module.network,
    module.vnet_peerings,
    module.monitoring
  ]
}

data "azurerm_resource_group" "infrastructure_rg" {
  name = data.terraform_remote_state.devops.outputs.resource_group_names.infrastructure
}

# Diagnostic settings for all Azure resources
module "monitoring_diagnostics" {
  source = "../../../../../modules/monitoring_diagnostics"

  # Default to zoneA workspace for non-regional resources
  workspace_id   = module.monitoring["zoneA"].workspace_id
  workspace_name = module.monitoring["zoneA"].workspace_name

  # Regional routing configuration
  workspace_ids_by_location = {
    for k, v in local.regions : k => module.monitoring[k].workspace_id
  }

  diagnostic_setting_name_prefix = module.naming.monitor_diagnostic_setting.name

  # VNets will use regional LAW
  diagnostic_virtual_network_ids = {
    for region_key, network_module in module.network : region_key => network_module.vnet_id
  }

  # Non-regional resources use zoneA LAW
  diagnostic_function_app_ids = {
    observability = module.observability.function_app_id
  }

  diagnostic_key_vault_ids = {
    core = module.kv.key_vault_id
  }

  diagnostic_application_insights_ids = {
    monitoring = module.monitoring["zoneA"].app_insights_id
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

resource "azurerm_key_vault_access_policy" "function_app_kv_policy" {
  key_vault_id       = module.kv.key_vault_id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = module.observability.function_app_identity_principal_id
  secret_permissions = ["Get", "List"]
}
