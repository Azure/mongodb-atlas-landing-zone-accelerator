resource "azurerm_key_vault" "self" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  network_acls {
    # If open_access is true, allow all; if false, restrict to VNet subnets
    default_action             = var.open_access ? "Allow" : "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.open_access ? [] : var.virtual_network_subnet_ids
  }
  access_policy {
    tenant_id           = var.tenant_id
    object_id           = var.admin_object_id
    key_permissions     = ["Get"]
    secret_permissions  = ["Get", "Set", "List"]
    storage_permissions = ["Get"]
  }
}

# Key Vault Secret with expiration and content type
resource "azurerm_key_vault_secret" "mongo_atlas_client_secret" {
  name            = "mongo-atlas-client-secret"
  value           = var.mongo_atlas_client_secret
  key_vault_id    = azurerm_key_vault.self.id
  content_type    = "MongoDB Atlas Client Secret"
  expiration_date = var.mongo_atlas_client_secret_expiration
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
}