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
# Associate NAT Gateway with SharedServicesSubnet
# -------------------------
resource "azurerm_subnet_nat_gateway_association" "shared_services_subnet_nat" {
  subnet_id      = azurerm_subnet.shared_services_subnet.id
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

# =================================================
# ManufacturingVnet NAT Gateway (West Europe)
# =================================================

# -------------------------
# Public IP for Manufacturing NAT Gateway
# -------------------------
resource "azurerm_public_ip" "mfg_nat_gateway_pip" {
  name                = "mfg-nat-gateway-pip"
  location            = azurerm_virtual_network.mfg_vnet.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags                = var.tags
}

# -------------------------
# Manufacturing NAT Gateway
# -------------------------
resource "azurerm_nat_gateway" "mfg_nat" {
  name                    = "mfg-nat-gateway"
  location                = azurerm_virtual_network.mfg_vnet.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
  tags                    = var.tags
}

# -------------------------
# Associate Public IP with Manufacturing NAT Gateway
# -------------------------
resource "azurerm_nat_gateway_public_ip_association" "mfg_nat_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.mfg_nat.id
  public_ip_address_id = azurerm_public_ip.mfg_nat_gateway_pip.id
}

# -------------------------
# Associate NAT Gateway with ManufacturingSystemsSubnet
# -------------------------
resource "azurerm_subnet_nat_gateway_association" "mfg_systems_subnet_nat" {
  subnet_id      = azurerm_subnet.mfg_systems_subnet.id
  nat_gateway_id = azurerm_nat_gateway.mfg_nat.id
}

# -------------------------
# Associate NAT Gateway with SensorSubnet1
# -------------------------
resource "azurerm_subnet_nat_gateway_association" "sensor1_subnet_nat" {
  subnet_id      = azurerm_subnet.sensor1_subnet.id
  nat_gateway_id = azurerm_nat_gateway.mfg_nat.id
}

# -------------------------
# Associate NAT Gateway with SensorSubnet2
# -------------------------
resource "azurerm_subnet_nat_gateway_association" "sensor2_subnet_nat" {
  subnet_id      = azurerm_subnet.sensor2_subnet.id
  nat_gateway_id = azurerm_nat_gateway.mfg_nat.id
}

# -------------------------
# Associate NAT Gateway with SensorSubnet3
# -------------------------
resource "azurerm_subnet_nat_gateway_association" "sensor3_subnet_nat" {
  subnet_id      = azurerm_subnet.sensor3_subnet.id
  nat_gateway_id = azurerm_nat_gateway.mfg_nat.id
}

output "mfg_nat_gateway_public_ip" {
  value       = azurerm_public_ip.mfg_nat_gateway_pip.ip_address
  description = "Public IP address of the Manufacturing NAT Gateway"
}

# =================================================
# ResearchVnet NAT Gateway (Southeast Asia)
# =================================================

# -------------------------
# Public IP for Research NAT Gateway
# -------------------------
resource "azurerm_public_ip" "research_nat_gateway_pip" {
  name                = "research-nat-gateway-pip"
  location            = azurerm_virtual_network.research_vnet.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags                = var.tags
}

# -------------------------
# Research NAT Gateway
# -------------------------
resource "azurerm_nat_gateway" "research_nat" {
  name                    = "research-nat-gateway"
  location                = azurerm_virtual_network.research_vnet.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
  tags                    = var.tags
}

# -------------------------
# Associate Public IP with Research NAT Gateway
# -------------------------
resource "azurerm_nat_gateway_public_ip_association" "research_nat_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.research_nat.id
  public_ip_address_id = azurerm_public_ip.research_nat_gateway_pip.id
}

# -------------------------
# Associate NAT Gateway with ResearchSystemSubnet
# -------------------------
resource "azurerm_subnet_nat_gateway_association" "research_subnet_nat" {
  subnet_id      = azurerm_subnet.research_subnet.id
  nat_gateway_id = azurerm_nat_gateway.research_nat.id
}

output "research_nat_gateway_public_ip" {
  value       = azurerm_public_ip.research_nat_gateway_pip.ip_address
  description = "Public IP address of the Research NAT Gateway"
}
