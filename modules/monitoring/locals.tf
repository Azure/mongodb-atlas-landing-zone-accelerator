locals {
  monitoring_dns_zone_definitions = {
    oms      = "privatelink.oms.opinsights.azure.com"
    ods      = "privatelink.ods.opinsights.azure.com"
    monitor  = "privatelink.monitor.azure.com"
    agentsvc = "privatelink.agentsvc.azure-automation.net"
    blob     = "privatelink.blob.core.windows.net"
  }
}