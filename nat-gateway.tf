# nat-gateway.tf

# -------------------------
# Public IP for NAT Gateway
# -------------------------
resource "azurerm_public_ip" "nat_gateway_pip" {
  name                = "nat-gateway-pip"
  location            = azurerm_virtual_network.core_vnet.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]  # NAT Gateway supports single zone only
  tags                = var.tags
}

# -------------------------
# NAT Gateway
# -------------------------
resource "azurerm_nat_gateway" "nat" {
  name                    = "core-nat-gateway"
  location                = azurerm_virtual_network.core_vnet.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]  # NAT Gateway supports single zone only
  tags                    = var.tags
}

# -------------------------
# Associate Public IP with NAT Gateway
# -------------------------
resource "azurerm_nat_gateway_public_ip_association" "nat_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_pip.id
}

# -------------------------
# Associate NAT Gateway with PublicWebServiceSubnet
# -------------------------
resource "azurerm_subnet_nat_gateway_association" "web_subnet_nat" {
  subnet_id      = azurerm_subnet.public_web_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

# -------------------------
# Associate NAT Gateway with DatabaseSubnet
# -------------------------
resource "azurerm_subnet_nat_gateway_association" "db_subnet_nat" {
  subnet_id      = azurerm_subnet.database_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

# -------------------------
# Outputs
# -------------------------
output "nat_gateway_public_ip" {
  value       = azurerm_public_ip.nat_gateway_pip.ip_address
  description = "Public IP address of the NAT Gateway"
}
