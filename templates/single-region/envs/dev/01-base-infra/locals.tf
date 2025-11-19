locals {
  environment = "dev"

  project_name = var.project_name

  tags = {
    environment = local.environment
    project     = local.project_name
  }

  org_id                   = var.org_id
  cluster_name             = var.cluster_name
  cluster_type             = "REPLICASET"
  instance_size            = "M10"
  backup_enabled           = true
  electable_nodes          = 3
  manual_connection        = true
  reference_hour_of_day    = 3
  reference_minute_of_hour = 45
  restore_window_days      = 4

  region_definition = data.terraform_remote_state.devops.outputs.region_definition["unique"]

  mongo_atlas_client_id                = var.mongo_atlas_client_id
  mongo_atlas_client_secret            = var.mongo_atlas_client_secret
  mongo_atlas_client_secret_expiration = timeadd(time_static.build_time.rfc3339, "8760h")
  purge_protection_enabled             = true
  soft_delete_retention_days           = 7

  # Log Analytics Workspace configuration
  log_analytics_workspace_sku                        = "PerGB2018"
  log_analytics_workspace_retention_in_days          = 30
  log_analytics_workspace_internet_ingestion_enabled = false
}
