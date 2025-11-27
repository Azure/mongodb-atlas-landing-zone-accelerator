locals {
  # Common
  location = "centralus"

  # Storage Account
  account_tier     = "Standard"
  replication_type = "ZRS"
  container_name   = "tfstate"
  subscription_id  = data.azurerm_client_config.current.subscription_id

  # Identity
  github_organization_name = var.github_organization_name
  github_repository_name   = var.github_repository_name
  environment              = "dev"

  audiences = ["api://AzureADTokenExchange"]
  issuer    = "https://token.actions.githubusercontent.com"

  federation = {
    federated_identity_name = "${lower(local.github_organization_name)}-${lower(local.github_repository_name)}-env-${lower(local.environment)}",
    subject                 = "repo:${local.github_organization_name}/${local.github_repository_name}:environment:${local.environment}"
  }

  tags = {
    environment = local.environment
    location    = local.location
  }

  organization_name = var.mongodb_atlas_organization_name
  first_name        = var.first_name
  last_name         = var.last_name
  email_address     = var.email_address
  publisher_id      = "mongodb"
  offer_id          = "mongodb_atlas_azure_native_prod"
  plan_id           = "azure_native"
  term_id           = "gmz7xq9ge3py"
  plan_name         = "Pay as You Go"
  term_unit         = "P1M"

  # Note: The proposed address space is for demonstration purposes. Please update them as needed.
  region_definition = {
    "unique" = {
      atlas_region                               = "US_CENTRAL"
      azure_region                               = "centralus"
      priority                                   = 7
      address_space                              = ["10.0.0.0/25"]
      app_workload_subnet_prefixes               = ["10.0.0.0/28"]
      observability_function_app_subnet_prefixes = ["10.0.0.16/28"]
      private_endpoints_subnet_prefixes          = ["10.0.0.32/27"]
      test_app_subnet_prefixes                   = ["10.0.0.64/28"] # This subnet is for step 2, which is optional and used to validate the connection with the cluster.
      private_subnet_name                        = "${module.infrastructure_naming.subnet.name_unique}-mongodb-app-workload-endpoint"
      observability_function_app_subnet_name     = "${module.infrastructure_naming.subnet.name_unique}-function-app"
      private_endpoints_subnet_name              = "${module.infrastructure_naming.subnet.name_unique}-shared-private-endpoints"
    }
  }
}
