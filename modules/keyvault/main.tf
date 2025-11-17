resource "azurerm_key_vault" "self" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days

  network_acls {
    # If open_access is true, allow all; if false, restrict to VNet subnets
    default_action = var.open_access ? "Allow" : "Deny"
    bypass         = "None"
  }
}

resource "azurerm_key_vault_secret" "mongo_atlas_client_secret" {
  name            = "mongo-atlas-client-secret"
  value           = var.mongo_atlas_client_secret
  key_vault_id    = azurerm_key_vault.self.id
  content_type    = "MongoDB Atlas Client Secret"
  expiration_date = var.mongo_atlas_client_secret_expiration

  depends_on = [azurerm_key_vault_access_policy.admin_kv_policy]
}

resource "azurerm_private_dns_zone" "vaultcore" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_link" {
  name                  = "${var.vnet_name}-kv-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.vaultcore.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = var.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = var.private_service_connection_name
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.self.id
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.vaultcore.id]
  }
}

resource "azurerm_key_vault_access_policy" "admin_kv_policy" {
  key_vault_id = azurerm_key_vault.self.id
  tenant_id    = var.tenant_id
  object_id    = var.admin_object_id

  secret_permissions  = ["Get", "Set", "List", "Delete"]
  key_permissions     = ["Get", "Delete"]
  storage_permissions = ["Get", "Delete"]
}
