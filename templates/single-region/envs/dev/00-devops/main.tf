data "azurerm_client_config" "current" {
}

module "devops" {
  source = "../../../../../modules/devops"

  # Common
  location = local.location
  tags     = local.tags

  # Resource groups
  resource_group_name_devops     = module.devops_naming.resource_group.name
  resource_groups_infrastructure = { "unique" : { name = module.infrastructure_naming.resource_group.name, location = local.location } }
  resource_groups_app            = { "unique" : { name = module.application_naming.resource_group.name, location = local.location } }

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
  source = "../../../../../modules/mongodb_marketplace"
  count  = var.should_create_mongo_org ? 1 : 0
  # Currently the MongoDB Marketplace offering is only available in East US 2
  location          = "eastus2"
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
