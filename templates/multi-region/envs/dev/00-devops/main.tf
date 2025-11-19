data "azurerm_client_config" "current" {
}

module "devops" {
  source = "../../../../../modules/devops"

  # Common
  location = local.location
  tags     = local.tags

  # Resource groups
  resource_group_name_devops = module.devops_naming.resource_group.name
  resource_groups_app = { for region_key, region in local.regions :
    region_key => {
      name     = module.application_naming[region_key].resource_group.name
      location = region.azure_region
    }
  }
  resource_groups_infrastructure = { for region_key, region in local.regions :
    region_key => {
      name     = module.infrastructure_naming[region_key].resource_group.name
      location = region.azure_region
    }
  }

  # Identity
  audiences  = local.audiences
  issuer     = local.issuer
  federation = local.federation

  # Storage Account
  storage_account_name = module.devops_naming.storage_account.name_unique
  replication_type     = local.replication_type
  account_tier         = local.account_tier
  container_name       = local.container_name
}

module "mongodb_marketplace" {
  source            = "../../../../../modules/mongodb_marketplace"
  count             = var.should_create_mongo_org ? 1 : 0
  location          = local.location
  subscription_id   = local.subscription_id
  resource_group_id = module.devops.identity_info.devops_resource_group_id

  publisher_id = local.publisher_id
  offer_id     = local.offer_id
  plan_id      = local.plan_id
  term_id      = local.term_id
  plan_name    = local.plan_name
  term_unit    = local.term_unit

  organization_name = local.organization_name

  first_name    = local.first_name
  last_name     = local.last_name
  email_address = local.email_address
}
