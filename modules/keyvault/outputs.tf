output "key_vault_id" {
  value = azurerm_key_vault.self.id
}

output "mongo_atlas_client_secret_uri" {
  value = azurerm_key_vault_secret.mongo_atlas_client_secret.id
}