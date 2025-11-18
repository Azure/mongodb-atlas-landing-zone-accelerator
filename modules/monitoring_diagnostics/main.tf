locals {
  diagnostic_setting_name_prefix = coalesce(var.diagnostic_setting_name_prefix, replace(lower(var.workspace_name), "_", "-"))

  diagnostic_function_app_targets = {
    for key, id in var.diagnostic_function_app_ids :
    lower(replace(key, "_", "-")) => id
  }

  diagnostic_key_vault_targets = {
    for key, id in var.diagnostic_key_vault_ids :
    lower(replace(key, "_", "-")) => id
  }

  diagnostic_virtual_network_targets = {
    for key, id in var.diagnostic_virtual_network_ids :
    key => id
  }

  diagnostic_application_insights_targets = {
    for key, id in var.diagnostic_application_insights_ids :
    lower(replace(key, "_", "-")) => id
  }

  diagnostic_storage_blob_service_targets = {
    for key, id in var.diagnostic_storage_blob_service_ids :
    lower(replace(key, "_", "-")) => id
  }

  diagnostic_storage_queue_service_targets = {
    for key, id in var.diagnostic_storage_queue_service_ids :
    lower(replace(key, "_", "-")) => id
  }

  diagnostic_storage_table_service_targets = {
    for key, id in var.diagnostic_storage_table_service_ids :
    lower(replace(key, "_", "-")) => id
  }

  diagnostic_storage_file_service_targets = {
    for key, id in var.diagnostic_storage_file_service_ids :
    lower(replace(key, "_", "-")) => id
  }

  # Filter out resources with zero log categories after fetching diagnostic categories
}

# Subnet and Private Endpoint diagnostic settings are not supported by Azure Monitor; they are intentionally omitted.

data "azurerm_monitor_diagnostic_categories" "function_apps" {
  for_each    = local.diagnostic_function_app_targets
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "function_apps" {
  for_each                   = local.diagnostic_function_app_targets
  name                       = lower("${local.diagnostic_setting_name_prefix}-${each.key}")
  target_resource_id         = each.value
  log_analytics_workspace_id = var.workspace_id

  dynamic "enabled_log" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.function_apps[each.key].log_category_types, []))
    content {
      category = enabled_log.value
    }
  }
}

# App Service Plans do not emit logs and metrics are intentionally excluded per requirements.
# Diagnostic settings for App Service Plans are skipped.

data "azurerm_monitor_diagnostic_categories" "key_vaults" {
  for_each    = local.diagnostic_key_vault_targets
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "key_vaults" {
  for_each                   = local.diagnostic_key_vault_targets
  name                       = lower("${local.diagnostic_setting_name_prefix}-${each.key}")
  target_resource_id         = each.value
  log_analytics_workspace_id = var.workspace_id

  dynamic "enabled_log" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.key_vaults[each.key].log_category_types, []))
    content {
      category = enabled_log.value
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "virtual_networks" {
  for_each    = local.diagnostic_virtual_network_targets
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "virtual_networks" {
  for_each                   = local.diagnostic_virtual_network_targets
  name                       = lower("${local.diagnostic_setting_name_prefix}-${each.key}")
  target_resource_id         = each.value
  log_analytics_workspace_id = var.workspace_ids_by_location[each.key]

  dynamic "enabled_log" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.virtual_networks[each.key].log_category_types, []))
    content {
      category = enabled_log.value
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "application_insights" {
  for_each    = local.diagnostic_application_insights_targets
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "application_insights" {
  for_each                   = local.diagnostic_application_insights_targets
  name                       = lower("${local.diagnostic_setting_name_prefix}-${each.key}")
  target_resource_id         = each.value
  log_analytics_workspace_id = var.workspace_id

  dynamic "enabled_log" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.application_insights[each.key].log_category_types, []))
    content {
      category = enabled_log.value
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "storage_blob_services" {
  for_each    = local.diagnostic_storage_blob_service_targets
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "storage_blob_services" {
  for_each                   = local.diagnostic_storage_blob_service_targets
  name                       = lower("${local.diagnostic_setting_name_prefix}-blob-${each.key}")
  target_resource_id         = each.value
  log_analytics_workspace_id = var.workspace_id

  dynamic "enabled_log" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.storage_blob_services[each.key].log_category_types, []))
    content {
      category = enabled_log.value
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "storage_queue_services" {
  for_each    = local.diagnostic_storage_queue_service_targets
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "storage_queue_services" {
  for_each                   = local.diagnostic_storage_queue_service_targets
  name                       = lower("${local.diagnostic_setting_name_prefix}-queue-${each.key}")
  target_resource_id         = each.value
  log_analytics_workspace_id = var.workspace_id

  dynamic "enabled_log" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.storage_queue_services[each.key].log_category_types, []))
    content {
      category = enabled_log.value
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "storage_table_services" {
  for_each    = local.diagnostic_storage_table_service_targets
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "storage_table_services" {
  for_each                   = local.diagnostic_storage_table_service_targets
  name                       = lower("${local.diagnostic_setting_name_prefix}-table-${each.key}")
  target_resource_id         = each.value
  log_analytics_workspace_id = var.workspace_id

  dynamic "enabled_log" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.storage_table_services[each.key].log_category_types, []))
    content {
      category = enabled_log.value
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "storage_file_services" {
  for_each    = local.diagnostic_storage_file_service_targets
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "storage_file_services" {
  for_each                   = local.diagnostic_storage_file_service_targets
  name                       = lower("${local.diagnostic_setting_name_prefix}-file-${each.key}")
  target_resource_id         = each.value
  log_analytics_workspace_id = var.workspace_id

  dynamic "enabled_log" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.storage_file_services[each.key].log_category_types, []))
    content {
      category = enabled_log.value
    }
  }
}
