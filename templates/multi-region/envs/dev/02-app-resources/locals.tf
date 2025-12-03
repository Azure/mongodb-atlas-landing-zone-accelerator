locals {
  environment = "dev"

  app_information_by_region = {
    for k, v in data.terraform_remote_state.devops.outputs.region_definitions :
    k => {
      location                 = v.azure_region
      app_service_plan_name    = "${module.naming.app_service_plan.name_unique}-${k}"
      app_service_plan_sku     = "B1" # Minimum SKU for VNet integration is B1
      app_web_app_name         = "${module.naming.app_service.name_unique}-${k}"
      virtual_network_name     = data.terraform_remote_state.common.outputs.vnets[k].name
      vnet_resource_group_name = data.terraform_remote_state.common.outputs.vnets[k].resource_group_name
      subnet_name              = "${module.naming.subnet.name_unique}-${k}"
      address_prefixes         = v.test_app_subnet_prefixes
    }
  }

  tags = {
    environment = local.environment
  }
}
