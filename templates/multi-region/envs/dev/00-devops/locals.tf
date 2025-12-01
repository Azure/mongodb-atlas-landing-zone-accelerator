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

  regions = {
    zoneA = {
      atlas_region = "US_CENTRAL"
      azure_region = "centralus"
    }
    zoneB = {
      atlas_region = "US_NORTH_CENTRAL"
      azure_region = "northcentralus"
    }
    zoneC = {
      atlas_region = "US_WEST_CENTRAL"
      azure_region = "westcentralus"
    }
  }

  # Note: The proposed address space is for demonstration purposes. Please update them as needed.
  # Disclaimer: The `node_count` must be either 3, 5, or 7. Refer to the official documentation for more details: https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/cluster.html?utm_source=chatgpt.com#electable_nodes-1
  region_definitions = {
    zoneA = {
      atlas_region                               = local.regions["zoneA"].atlas_region
      azure_region                               = local.regions["zoneA"].azure_region
      priority                                   = 7
      address_space                              = ["10.0.0.0/25"]
      app_workload_subnet_prefixes               = ["10.0.0.0/28"]
      observability_function_app_subnet_prefixes = ["10.0.0.16/28"]
      private_endpoints_subnet_prefixes          = ["10.0.0.32/27"]
      test_app_subnet_prefixes                   = ["10.0.0.64/28"] # This subnet is for step 2, which is optional and used to validate the connection with the cluster.
      app_workload_subnet_name                   = "${module.infrastructure_naming["zoneA"].subnet.name_unique}-mongodb-app-workload-endpoint"
      observability_function_app_subnet_name     = "${module.infrastructure_naming["zoneA"].subnet.name_unique}-function-app"
      private_endpoints_subnet_name              = "${module.infrastructure_naming["zoneA"].subnet.name_unique}-shared-private-endpoints"
      deploy_observability_subnets               = true
      has_keyvault_private_endpoint              = true
      has_observability_storage_account          = true
      node_count                                 = 2
    }
    zoneB = {
      atlas_region                      = local.regions["zoneB"].atlas_region
      azure_region                      = local.regions["zoneB"].azure_region
      priority                          = 6
      address_space                     = ["10.0.0.128/27"]
      app_workload_subnet_prefixes      = ["10.0.0.128/28"]
      test_app_subnet_prefixes          = ["10.0.0.144/28"] # This subnet is for step 2, which is optional and used to validate the connection with the cluster.
      app_workload_subnet_name          = "${module.infrastructure_naming["zoneB"].subnet.name_unique}-mongodb-app-workload-endpoint"
      deploy_observability_subnets      = false
      has_keyvault_private_endpoint     = false
      has_observability_storage_account = false
      node_count                        = 2
    }
    zoneC = {
      atlas_region                      = local.regions["zoneC"].atlas_region
      azure_region                      = local.regions["zoneC"].azure_region
      priority                          = 5
      address_space                     = ["10.0.0.160/27"]
      app_workload_subnet_prefixes      = ["10.0.0.160/28"]
      test_app_subnet_prefixes          = ["10.0.0.176/28"] # This subnet is for step 2, which is optional and used to validate the connection with the cluster.
      app_workload_subnet_name          = "${module.infrastructure_naming["zoneC"].subnet.name_unique}-mongodb-app-workload-endpoint"
      deploy_observability_subnets      = false
      has_keyvault_private_endpoint     = false
      has_observability_storage_account = false
      node_count                        = 1
    }
  }
}
