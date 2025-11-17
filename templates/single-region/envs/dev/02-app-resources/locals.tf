locals {
  location              = "eastus2"
  app_service_plan_name = module.naming.app_service_plan.name
  app_service_plan_sku  = "B1" # Minimum SKU for VNet integration is B1
  app_web_app_name      = module.naming.app_service.name_unique
  virtual_network_name  = data.terraform_remote_state.common.outputs.vnet_name
  subnet_name           = module.naming.subnet.name
  address_prefixes      = ["10.0.0.64/29"] # Adjust based on your network design
  tags = {
    environment = "dev"
    app_name    = local.app_web_app_name
  }
}
