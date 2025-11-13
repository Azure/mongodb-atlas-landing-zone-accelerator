locals {
  location    = "eastus2"
  environment = "dev"

  project_name = var.project_name

  vnet_address_space = ["10.0.0.0/26"]

  private_subnet_prefixes                        = ["10.0.0.0/29"]
  observability_function_app_subnet_prefixes     = ["10.0.0.8/29"]
  observability_private_endpoint_subnet_prefixes = ["10.0.0.16/28"]
  observability_storage_account_subnet_prefixes  = ["10.0.0.32/28"]
  keyvault_private_endpoint_subnet_prefixes      = ["10.0.0.48/28"]

  private_subnet_name                        = "${module.naming.subnet.name_unique}-mongodb-private-endpoint"
  observability_function_app_subnet_name     = "${module.naming.subnet.name_unique}-function-app"
  observability_private_endpoint_subnet_name = "${module.naming.subnet.name_unique}-observability-private-endpoint"
  observability_storage_account_subnet_name  = "${module.naming.subnet.name_unique}-observability-sa-private-endpoint"
  keyvault_private_endpoint_subnet_name      = "${module.naming.subnet.name_unique}-kv-private-endpoint"

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
  now                                  = timestamp()
  mongo_atlas_client_secret_expiration = timeadd(local.now, "8760h")
}