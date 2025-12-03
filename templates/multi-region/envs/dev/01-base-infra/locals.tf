locals {
  environment = "dev"

  project_name = var.project_name

  tags = {
    environment = local.environment
    project     = local.project_name
  }

  org_id                   = var.org_id
  cluster_name             = var.cluster_name
  cluster_type             = "REPLICASET"
  backup_enabled           = true
  reference_hour_of_day    = 3
  reference_minute_of_hour = 45
  restore_window_days      = 4

  naming_suffix_base = "inframulregion"

  region_definitions = data.terraform_remote_state.devops.outputs.region_definitions

  # For Atlas cluster
  # Disclaimer: Ensure that the `instance_size` is consistent across all regions specified in `region_configs`. Refer to the official documentation for more details: https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/advanced_cluster#electable_specs-1
  region_configs = {
    for k, v in local.region_definitions : k => {
      atlas_region = v.atlas_region
      azure_region = v.azure_region
      priority     = v.priority
      electable_specs = {
        instance_size = "M10"
        node_count    = v.node_count
      }
    }
  }

  # For Azure resources
  regions = {
    for k, v in local.region_definitions : k => {
      location                                   = v.azure_region
      address_space                              = v.address_space
      app_workload_subnet_prefixes               = v.app_workload_subnet_prefixes
      app_workload_subnet_name                   = v.app_workload_subnet_name
      manual_connection                          = true
      deploy_observability_function              = v.deploy_observability_function
      observability_function_app_subnet_prefixes = v.deploy_observability_function ? v.observability_function_app_subnet_prefixes : null
      observability_function_app_subnet_name     = v.deploy_observability_function ? v.observability_function_app_subnet_name : null
      private_endpoints_subnet_prefixes          = (v.deploy_observability_function) ? v.private_endpoints_subnet_prefixes : null
      private_endpoints_subnet_name              = (v.deploy_observability_function) ? v.private_endpoints_subnet_name : null
    }
  }

  vnet_keys  = sort(keys(module.network))
  pair_list  = flatten([for i, a in local.vnet_keys : [for j, b in local.vnet_keys : { key = "${a}|${b}", a = a, b = b } if i < j]])
  vnet_pairs = { for p in local.pair_list : p.key => { a = p.a, b = p.b } }

  mongo_atlas_client_id                = var.mongo_atlas_client_id
  mongo_atlas_client_secret            = var.mongo_atlas_client_secret
  mongo_atlas_client_secret_expiration = timeadd(time_static.build_time.rfc3339, "8760h")
  purge_protection_enabled             = true
  soft_delete_retention_days           = 7

  ## Monitoring configuration
  # Log Analytics Workspace configuration
  log_analytics_workspace_sku                        = "PerGB2018"
  log_analytics_workspace_retention_in_days          = 30
  log_analytics_workspace_internet_ingestion_enabled = false

  common_security_rules = {

    # Allow traffic originating from inside the VNet to any destination within the VNet
    allow_vnet_inbound = {
      name                       = "AllowAllInFromVNetInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      source_port_range          = "*"
      destination_port_range     = "*"
      description                = "Allow inbound traffic from within the Virtual Network."
    }

    # Default deny rule for inbound traffic, denies all inbound connections not previously allowed or denied
    deny_all_inbound = {
      name                       = "DenyAllInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      description                = "Deny all inbound traffic by default."
    }

    # Deny all outbound traffic not explicitly allowed
    deny_all_outbound = {
      name                       = "DenyAllOutbound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      description                = "Deny all other outbound traffic by default."
    }
  }

  specific_security_rules = {
    allow_internet_https_outbound = {
      # Allow outbound HTTPS connections to the Internet (for example, to access external APIs such as MongoDB Atlas)
      name                       = "AllowInternetHTTPS"
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      source_port_range          = "*"
      destination_port_range     = "443"
      description                = "Allow outbound TCP traffic to the Internet on port 443 for secure API calls (e.g., MongoDB Atlas Metrics API)."
    }

    allow_vnet_outbound = {
      name                       = "AllowVNetOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
      source_port_range          = "*"
      destination_port_range     = "*"
      description                = "Allow outbound traffic to resources within the Virtual Network."
    }

    allow_dns_outbound = {
      name                       = "AllowDNS"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureDNS"
      source_port_range          = "*"
      destination_port_range     = "53"
      description                = "Allow outbound UDP traffic to Azure DNS for DNS resolution (port 53)."
    }
  }

  subnets_definitions = {
    for region_key, region in local.regions :
    region_key => {
      app_workload_subnet_prefixes = {
        name             = region.app_workload_subnet_name
        address_prefixes = region.app_workload_subnet_prefixes
        security_rules   = merge(local.common_security_rules, local.specific_security_rules)
      }
      observability_function_app = region.deploy_observability_function ? {
        name             = region.observability_function_app_subnet_name
        address_prefixes = region.observability_function_app_subnet_prefixes
        security_rules   = merge(local.common_security_rules, local.specific_security_rules)
        delegation = {
          name = "functionapp-delegation"
          service_delegation = {
            name    = "Microsoft.App/environments"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      } : null
      private_endpoints = (
        region.deploy_observability_function
        ) ? {
        name             = region.private_endpoints_subnet_name
        address_prefixes = region.private_endpoints_subnet_prefixes
        security_rules   = local.common_security_rules
      } : null
    }
  }
}
