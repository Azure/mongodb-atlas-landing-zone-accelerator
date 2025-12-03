data "azurerm_monitor_diagnostic_categories" "targets" {
  for_each    = var.diagnostic_targets.resources
  resource_id = each.value.id
}

resource "azurerm_monitor_diagnostic_setting" "targets" {
  for_each                   = var.diagnostic_targets.resources
  name                       = "${var.diagnostic_setting_name}-${replace(each.key, "_", "-")}"
  log_analytics_workspace_id = var.diagnostic_targets.workspace_id
  target_resource_id         = each.value.id

  dynamic "enabled_log" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.targets[each.key].log_category_types, []))
    content {
      category = enabled_log.value
    }
  }
}
