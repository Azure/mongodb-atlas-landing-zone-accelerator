# Unable to use Managed Identity in the azurerm_function_app_flex_consumption resource due to a Terraform provider bug (https://github.com/hashicorp/terraform-provider-azurerm/issues/30732). In production, implement proper authentication using Entra ID and not pre-shared keys. Disable key-based access on the Storage account.
resource "azurerm_storage_account" "observability_function_storage" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action = "Deny"
  }
}

resource "azurerm_storage_container" "observability_function_container" {
  name                  = "observability-function"
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.observability_function_storage.id
}

resource "azurerm_service_plan" "observability_function_plan" {
  name                = var.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "FC1"
  os_type             = "Linux"
}

resource "azurerm_function_app_flex_consumption" "observability_function" {
  name                = var.function_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.observability_function_plan.id

  storage_container_type     = "blobContainer"
  storage_container_endpoint = "${azurerm_storage_account.observability_function_storage.primary_blob_endpoint}${azurerm_storage_container.observability_function_container.name}"

  # Unable to use Managed Identity due to a Terraform provider bug (https://github.com/hashicorp/terraform-provider-azurerm/issues/30732). In production, implement proper authentication using Entra ID and not pre-shared keys. Disable key-based access on the Storage account.
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.observability_function_storage.primary_access_key

  runtime_name           = "dotnet-isolated"
  runtime_version        = "8.0"
  maximum_instance_count = 40
  instance_memory_in_mb  = 2048

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    "MONGODB_CLIENT_ID"                     = var.mongo_atlas_client_id
    "MONGODB_CLIENT_SECRET"                 = format("@Microsoft.KeyVault(SecretUri=%s)", var.mongo_atlas_client_secret_kv_uri)
    "MONGODB_GROUP_NAME"                    = var.mongo_group_name
    "AzureWebJobsStorage"                   = azurerm_storage_account.observability_function_storage.primary_connection_string
    "FUNCTIONS_EXTENSION_VERSION"           = "~4"
    "FUNCTION_FREQUENCY_CRON"               = var.function_frequency_cron
    "MONGODB_INCLUDED_METRICS"              = var.mongodb_included_metrics
    "MONGODB_EXCLUDED_METRICS"              = var.mongodb_excluded_metrics
  }

  identity {
    type = "SystemAssigned"
  }

  virtual_network_subnet_id = var.function_subnet_id

  site_config {
    vnet_route_all_enabled = true
  }

  public_network_access_enabled = var.open_access

  # Ignore changes to Application Insights connection string and Storage account settings managed by Azure
  lifecycle {
    ignore_changes = [
      site_config[0].application_insights_connection_string,
      app_settings["APPLICATIONINSIGHTS_CONNECTION_STRING"],
      app_settings["AzureWebJobsStorage"],
    ]
  }
}

resource "azurerm_role_assignment" "functionToStorage1" {
  scope                = azurerm_storage_account.observability_function_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.observability_function.identity[0].principal_id
}

resource "azurerm_role_assignment" "functionToStorage2" {
  scope                = azurerm_storage_account.observability_function_storage.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = azurerm_function_app_flex_consumption.observability_function.identity[0].principal_id
}

resource "azurerm_role_assignment" "functionToStorage3" {
  scope                = azurerm_storage_account.observability_function_storage.id
  role_definition_name = "Reader and Data Access"
  principal_id         = azurerm_function_app_flex_consumption.observability_function.identity[0].principal_id
}
