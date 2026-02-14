# lb.tf - Internal Load Balancer for CoreServicesVnet

# -------------------------
# Load Balancer
# -------------------------
resource "azurerm_lb" "core_lb" {
  name                = "LB-1"
  location            = azurerm_virtual_network.core_vnet.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  sku_tier            = "Regional"
  
  frontend_ip_configuration {
    name                          = "LB-FE-IP"
    subnet_id                     = azurerm_subnet.shared_services_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = var.tags
}

# -------------------------
# Backend Address Pool
# -------------------------
resource "azurerm_lb_backend_address_pool" "core_pool" {
  name            = "LB-BE-POOL-1"
  loadbalancer_id = azurerm_lb.core_lb.id
}

# -------------------------
# Health Probe
# -------------------------
resource "azurerm_lb_probe" "http_probe" {
  name                = "LB-HP-1"
  loadbalancer_id     = azurerm_lb.core_lb.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 1
}

# -------------------------
# Load Balancing Rule
# -------------------------
resource "azurerm_lb_rule" "http_rule" {
  name                           = "LB-Rule-1"
  loadbalancer_id                = azurerm_lb.core_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LB-FE-IP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.core_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
  disable_outbound_snat          = true
  idle_timeout_in_minutes        = 4
}

# -------------------------
# Associate Web Server NIC to Backend Pool
# -------------------------
resource "azurerm_network_interface_backend_address_pool_association" "web_lb" {
  network_interface_id    = azurerm_network_interface.web_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.core_pool.id
}

# -------------------------
# Associate Database Server NIC to Backend Pool
# -------------------------
resource "azurerm_network_interface_backend_address_pool_association" "db_lb" {
  network_interface_id    = azurerm_network_interface.db_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.core_pool.id
}

# -------------------------
# DNS A Record for Load Balancer
# -------------------------
resource "azurerm_private_dns_a_record" "lb" {
  name                = "loadbalancer"
  zone_name           = azurerm_private_dns_zone.azure_poms.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_lb.core_lb.frontend_ip_configuration[0].private_ip_address]
  
  tags = var.tags
}

# -------------------------
# Outputs
# -------------------------
output "lb_frontend_ip" {
  value       = azurerm_lb.core_lb.frontend_ip_configuration[0].private_ip_address
  description = "Internal Load Balancer Frontend IP"
}

output "lb_fqdn" {
  value       = "${azurerm_private_dns_a_record.lb.name}.${azurerm_private_dns_zone.azure_poms.name}"
  description = "Load Balancer DNS name"
}

output "lb_test_command" {
  value       = "curl http://${azurerm_private_dns_a_record.lb.name}.${azurerm_private_dns_zone.azure_poms.name}"
  description = "Test LB from Ansible VM using DNS"
}
