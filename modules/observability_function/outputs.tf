output "observability_function_default_hostname" {
  value       = azurerm_function_app_flex_consumption.observability_function.default_hostname
  description = "Default hostname for the observability function app."
}

output "function_app_identity_principal_id" {
  value       = azurerm_function_app_flex_consumption.observability_function.identity[0].principal_id
  description = "Principal ID of the function app's managed identity"
}

output "storage_account_id" {
  value       = azurerm_storage_account.observability_function_storage.id
  description = "ID of the storage account backing the observability function app."
}

output "function_app_id" {
  value       = azurerm_function_app_flex_consumption.observability_function.id
  description = "ID of the observability function app."
}

output "app_service_plan_id" {
  value       = azurerm_service_plan.observability_function_plan.id
  description = "ID of the service plan hosting the observability function app."
}

output "storage_blob_service_id" {
  value       = "${azurerm_storage_account.observability_function_storage.id}/blobServices/default"
  description = "ID of the Storage Account Blob Service."
}

output "storage_queue_service_id" {
  value       = "${azurerm_storage_account.observability_function_storage.id}/queueServices/default"
  description = "ID of the Storage Account Queue Service."
}

output "storage_table_service_id" {
  value       = "${azurerm_storage_account.observability_function_storage.id}/tableServices/default"
  description = "ID of the Storage Account Table Service."
}

output "storage_file_service_id" {
  value       = "${azurerm_storage_account.observability_function_storage.id}/fileServices/default"
  description = "ID of the Storage Account File Service."
}
