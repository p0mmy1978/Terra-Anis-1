# app-gateway.tf

# -------------------------
# Public IP for Application Gateway
# -------------------------
resource "azurerm_public_ip" "appgw_pip" {
  name                = "lab-appgw-pip"
  location            = azurerm_virtual_network.core_vnet.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "lab-appgw"
  tags                = var.tags
}

# -------------------------
# Application Gateway
# -------------------------
resource "azurerm_application_gateway" "lab_appgw" {
  name                = "lab-app-gateway"
  location            = azurerm_virtual_network.core_vnet.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  frontend_port {
    name = "http-80"
    port = 80
  }

  # ---- Backend Pools ----

  backend_address_pool {
    name         = "web-backend-pool"
    ip_addresses = [azurerm_network_interface.web_nic.private_ip_address]
  }

  backend_address_pool {
    name         = "mfg-backend-pool"
    ip_addresses = [azurerm_network_interface.mfg_nic.private_ip_address]
  }

  # ---- Backend HTTP Settings ----

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  # ---- HTTP Listeners ----
  # Catch-all (no hostname) — handles requests by IP or unmatched hostnames
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "http-80"
    protocol                       = "Http"
  }

  # Host-based: web.poms.tech → WebServer-01
  http_listener {
    name                           = "web-host-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "http-80"
    protocol                       = "Http"
    host_name                      = "web.poms.tech"
  }

  # Host-based: mfg.poms.tech → MfgServer-01
  http_listener {
    name                           = "mfg-host-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "http-80"
    protocol                       = "Http"
    host_name                      = "mfg.poms.tech"
  }

  # ---- URL Path Map ----
  # /web  → WebServer-01 (CoreVNet, East US)
  # /mfg  → MfgServer-01 (ManufacturingVnet, West Europe, via VNet peering)
  # default → WebServer-01

  url_path_map {
    name                               = "path-map"
    default_backend_address_pool_name  = "web-backend-pool"
    default_backend_http_settings_name = "http-settings"

    path_rule {
      name                       = "web-rule"
      paths                      = ["/web", "/web/*"]
      backend_address_pool_name  = "web-backend-pool"
      backend_http_settings_name = "http-settings"
      rewrite_rule_set_name      = "strip-path-prefix"
    }

    path_rule {
      name                       = "mfg-rule"
      paths                      = ["/mfg", "/mfg/*"]
      backend_address_pool_name  = "mfg-backend-pool"
      backend_http_settings_name = "http-settings"
      rewrite_rule_set_name      = "strip-path-prefix"
    }
  }

  # ---- URL Rewrite Rules ----
  # Strip /web and /mfg prefixes so the backend receives / instead of /web/ or /mfg/

  rewrite_rule_set {
    name = "strip-path-prefix"

    rewrite_rule {
      name          = "strip-web-prefix"
      rule_sequence = 100

      condition {
        variable    = "var_uri_path"
        pattern     = "^/web/?(.*)"
        ignore_case = true
        negate      = false
      }

      url {
        path = "/{var_uri_path_1}"
      }
    }

    rewrite_rule {
      name          = "strip-mfg-prefix"
      rule_sequence = 200

      condition {
        variable    = "var_uri_path"
        pattern     = "^/mfg/?(.*)"
        ignore_case = true
        negate      = false
      }

      url {
        path = "/{var_uri_path_1}"
      }
    }
  }

  # ---- SSL Policy (TLS 1.2+ required, Azure deprecated older defaults) ----

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  # ---- Routing Rules ----

  # Host-based rules first (lower number = higher priority)
  # web.poms.tech → WebServer-01
  request_routing_rule {
    name                       = "web-host-rule"
    rule_type                  = "Basic"
    http_listener_name         = "web-host-listener"
    backend_address_pool_name  = "web-backend-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 100
  }

  # mfg.poms.tech → MfgServer-01
  request_routing_rule {
    name                       = "mfg-host-rule"
    rule_type                  = "Basic"
    http_listener_name         = "mfg-host-listener"
    backend_address_pool_name  = "mfg-backend-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 200
  }

  # Catch-all: IP access with /web or /mfg paths (lowest priority)
  request_routing_rule {
    name               = "path-based-rule"
    rule_type          = "PathBasedRouting"
    http_listener_name = "http-listener"
    url_path_map_name  = "path-map"
    priority           = 300
  }

  depends_on = [
    azurerm_linux_virtual_machine.web_vm,
    azurerm_linux_virtual_machine.mfg_vm
  ]

  tags = var.tags
}

# -------------------------
# Outputs
# -------------------------
output "appgw_public_ip_address" {
  value       = azurerm_public_ip.appgw_pip.ip_address
  description = "Public IP address of the Application Gateway"
}

output "appgw_public_ip_name" {
  value       = azurerm_public_ip.appgw_pip.name
  description = "Name of the Application Gateway public IP"
}

output "appgw_fqdn" {
  value       = azurerm_public_ip.appgw_pip.fqdn
  description = "Azure DNS name for the Application Gateway (CNAME this in Hostinger)"
}
