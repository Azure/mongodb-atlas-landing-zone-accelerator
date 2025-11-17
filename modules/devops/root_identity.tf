resource "azurerm_user_assigned_identity" "identity" {
  location            = var.location
  name                = "root-identity"
  resource_group_name = azurerm_resource_group.devops_rg.name
}

resource "azurerm_federated_identity_credential" "federated_identity" {
  name                = var.federation.federated_identity_name
  subject             = var.federation.subject
  audience            = var.audiences
  issuer              = var.issuer
  resource_group_name = azurerm_resource_group.devops_rg.name
  parent_id           = azurerm_user_assigned_identity.identity.id
}

locals {
  permissions_to_create = [
    azurerm_resource_group.devops_rg,
    azurerm_resource_group.infrastructure_rg
  ]
}

resource "azurerm_role_assignment" "permissions_admin" {
  for_each = { for rg in local.permissions_to_create : rg.name => rg }

  scope                = each.value.id
  role_definition_name = "User Access Administrator"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_role_assignment" "permissions_contributor" {
  for_each = { for rg in local.permissions_to_create : rg.name => rg }

  scope                = each.value.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}
resource "azurerm_role_assignment" "optional_permission" {
  count = length(var.resource_group_name_app) > 0 ? 1 : 0

  scope                = azurerm_resource_group.application_rg[0].id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_role_assignment" "blob_data_contributor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}
