# traffic-manager.tf - Azure Traffic Manager with Performance routing

# -------------------------
# Traffic Manager Profile
# -------------------------
resource "azurerm_traffic_manager_profile" "poms" {
  name                   = "poms"
  resource_group_name    = azurerm_resource_group.rg.name
  traffic_routing_method = "Performance"

  dns_config {
    relative_name = "poms"
    ttl           = 60
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }

  tags = var.tags
}

# -------------------------
# Azure Endpoints (one per web app region)
# -------------------------
resource "azurerm_traffic_manager_azure_endpoint" "webapp" {
  for_each = local.webapps

  name               = "poms-ep-${each.key}"
  profile_id         = azurerm_traffic_manager_profile.poms.id
  target_resource_id = azurerm_linux_web_app.webapp[each.key].id
  weight             = 1
}

# -------------------------
# Outputs
# -------------------------
output "traffic_manager_fqdn" {
  value       = "https://${azurerm_traffic_manager_profile.poms.fqdn}"
  description = "Traffic Manager FQDN"
}
