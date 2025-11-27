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
  instance_size            = "M10"
  backup_enabled           = true
  electable_nodes          = 3
  manual_connection        = true
  reference_hour_of_day    = 3
  reference_minute_of_hour = 45
  restore_window_days      = 4

  region_definition = data.terraform_remote_state.devops.outputs.region_definition["unique"]

  mongo_atlas_client_id                = var.mongo_atlas_client_id
  mongo_atlas_client_secret            = var.mongo_atlas_client_secret
  mongo_atlas_client_secret_expiration = timeadd(time_static.build_time.rfc3339, "8760h")
  purge_protection_enabled             = true
  soft_delete_retention_days           = 7

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
    app_workload_subnet_prefixes = {
      name             = local.region_definition.private_subnet_name
      address_prefixes = local.region_definition.app_workload_subnet_prefixes
      security_rules   = merge(local.common_security_rules, local.specific_security_rules)
    }
    observability_function_app = {
      name             = local.region_definition.observability_function_app_subnet_name
      address_prefixes = local.region_definition.observability_function_app_subnet_prefixes
      security_rules   = merge(local.common_security_rules, local.specific_security_rules)
      delegation = {
        name = "functionapp-delegation"
        service_delegation = {
          name    = "Microsoft.App/environments"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
    private_endpoints = {
      name             = local.region_definition.private_endpoints_subnet_name
      address_prefixes = local.region_definition.private_endpoints_subnet_prefixes
      security_rules   = local.common_security_rules
    }
  }
}
