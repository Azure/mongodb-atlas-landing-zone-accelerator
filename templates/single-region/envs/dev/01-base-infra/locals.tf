locals {
  # General Configuration
  location    = "eastus2"
  environment = "dev"

  project_name = var.project_name

  vnet_address_space = ["10.0.0.0/24"]

  # Subnet CIDR blocks
  # Layout: 10.0.0.0/25 provides 128 IPs (0-127)
  private_subnet_prefixes                       = ["10.0.0.0/28"]
  observability_function_app_subnet_prefixes    = ["10.0.0.16/28"]
  keyvault_private_endpoint_subnet_prefixes     = ["10.0.0.32/27"]
  monitoring_ampls_subnet_prefixes              = ["10.0.0.64/27"]
  observability_storage_account_subnet_prefixes = ["10.0.0.96/27"]

  # Subnet names
  private_subnet_name                       = "${module.naming.subnet.name_unique}-mongodb-private-endpoint"
  observability_function_app_subnet_name    = "${module.naming.subnet.name_unique}-function-app"
  monitoring_ampls_subnet_name              = "${module.naming.subnet.name_unique}-monitoring-ampls"
  observability_storage_account_subnet_name = "${module.naming.subnet.name_unique}-observability-sa-private-endpoint"
  keyvault_private_endpoint_subnet_name     = "${module.naming.subnet.name_unique}-kv-private-endpoint"

  tags = {
    environment = local.environment
    project     = local.project_name
  }

  org_id                   = var.org_id
  cluster_name             = var.cluster_name
  cluster_type             = "REPLICASET"
  instance_size            = "M10"
  backup_enabled           = true
  region                   = "US_EAST_2"
  electable_nodes          = 3
  priority                 = 7
  manual_connection        = true
  reference_hour_of_day    = 3
  reference_minute_of_hour = 45
  restore_window_days      = 4

  mongo_atlas_client_id                = var.mongo_atlas_client_id
  mongo_atlas_client_secret            = var.mongo_atlas_client_secret
  mongo_atlas_client_secret_expiration = timeadd(time_static.build_time.rfc3339, "8760h")
  purge_protection_enabled             = true
  soft_delete_retention_days           = 7

  # Observability Configuration
  # For Flex Consumption plan the minimum instance count is 40: https://learn.microsoft.com/en-us/azure/azure-functions/event-driven-scaling?tabs=azure-cli#flex-consumption-plan
  maximum_instance_count = 40

  # Log Analytics Workspace configuration
  log_analytics_workspace_sku                        = "PerGB2018"
  log_analytics_workspace_retention_in_days          = 30
  log_analytics_workspace_internet_ingestion_enabled = false
}
