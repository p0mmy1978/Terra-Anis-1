# lb.tf

# -------------------------
# Internal Load Balancer
# -------------------------
resource "azurerm_lb" "internal_lb" {
  name                = "internal-lb"
  location            = azurerm_virtual_network.core_vnet.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name                          = "internal-lb-frontend"
    subnet_id                     = azurerm_subnet.public_web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# -------------------------
# Backend Address Pool
# -------------------------
resource "azurerm_lb_backend_address_pool" "web_backend_pool" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "web-backend-pool"
}

# -------------------------
# Associate WebServer-01 NIC with Backend Pool
# -------------------------
resource "azurerm_network_interface_backend_address_pool_association" "web_nic_backend" {
  network_interface_id    = azurerm_network_interface.web_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_backend_pool.id
}

# -------------------------
# Associate DatabaseServer-01 NIC with Backend Pool
# -------------------------
resource "azurerm_network_interface_backend_address_pool_association" "db_nic_backend" {
  network_interface_id    = azurerm_network_interface.db_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_backend_pool.id
}

# -------------------------
# Health Probe
# -------------------------
resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "http-probe"
  protocol        = "Http"
  port            = 80
  request_path    = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# -------------------------
# Load Balancing Rule
# -------------------------
resource "azurerm_lb_rule" "http_rule" {
  loadbalancer_id                = azurerm_lb.internal_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "internal-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
  enable_tcp_reset               = true
  idle_timeout_in_minutes        = 15
  disable_outbound_snat          = true  # NAT Gateway handles outbound, not LB
}

# -------------------------
# Private DNS A Record for Load Balancer
# -------------------------
resource "azurerm_private_dns_a_record" "lb_dns" {
  name                = "loadbalancer"
  zone_name           = azurerm_private_dns_zone.azure_poms.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_lb.internal_lb.private_ip_address]
  tags                = var.tags

  depends_on = [azurerm_lb.internal_lb]
}

# -------------------------
# Outputs
# -------------------------
output "load_balancer_private_ip" {
  value       = azurerm_lb.internal_lb.private_ip_address
  description = "Private IP address of the Internal Load Balancer"
}

output "load_balancer_fqdn" {
  value       = "loadbalancer.azure.poms.tech"
  description = "DNS name for the Internal Load Balancer"
}
