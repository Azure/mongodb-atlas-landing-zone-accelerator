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
    observability_private_endpoint = each.value.deploy_observability_subnets ? {
      name             = each.value.observability_private_endpoint_subnet_name
      address_prefixes = each.value.observability_private_endpoint_subnet_prefixes
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
  log_analytics_workspace_name     = module.naming.log_analytics_workspace.name_unique
  app_insights_name                = module.naming.application_insights.name_unique
  function_app_name                = module.naming.function_app.name_unique
  service_plan_name                = module.naming.app_service_plan.name_unique
  storage_account_name             = module.naming.storage_account.name_unique
  mongo_atlas_client_id            = local.mongo_atlas_client_id
  mongo_group_name                 = local.project_name
  function_subnet_id               = module.network["zoneA"].subnet_ids["observability_function_app"]
  private_link_scope_name          = "private_link_scope_sr"
  appinsights_assoc_name           = "private_link_appi_association"
  pe_name                          = module.naming.private_endpoint.name_unique
  network_interface_name           = module.naming.network_interface.name_unique
  private_service_connection_name  = module.naming.private_service_connection.name_unique
  vnet_id                          = module.network["zoneA"].vnet_id
  vnet_name                        = module.network["zoneA"].vnet_name
  ampls_pe_subnet_id               = module.network["zoneA"].subnet_ids["observability_private_endpoint"]
  function_frequency_cron          = var.function_frequency_cron
  mongodb_included_metrics         = var.mongodb_included_metrics
  mongodb_excluded_metrics         = var.mongodb_excluded_metrics
  storage_account_pe_subnet_id     = module.network["zoneA"].subnet_ids["observability_storage_account"]
  mongo_atlas_client_secret_kv_uri = module.kv.mongo_atlas_client_secret_uri
  open_access                      = var.open_access

  depends_on = [
    module.network,
    module.vnet_peerings
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
