resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "eastus" # RG can be anywhere; resources have their own regions
  tags     = var.tags
}

# -------------------------
# Southeast Asia - ResearchVnet
# -------------------------
resource "azurerm_virtual_network" "research_vnet" {
  name                = "ResearchVnet"
  location            = "southeastasia"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.40.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "research_subnet" {
  name                 = "ResearchSystemSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.research_vnet.name
  address_prefixes     = ["10.40.0.0/24"]
}

# -------------------------
# East US - CoreServicesVnet
# -------------------------
resource "azurerm_virtual_network" "core_vnet" {
  name                = "CoreServicesVnet"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.20.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet" # must be exactly this name for Azure VPN/ER gateways
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.0.0/27"]
}

resource "azurerm_subnet" "shared_services_subnet" {
  name                 = "SharedServicesSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.10.0/24"]
}

resource "azurerm_subnet" "database_subnet" {
  name                 = "DatabaseSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.20.0/24"]
}

resource "azurerm_subnet" "public_web_subnet" {
  name                 = "PublicWebServiceSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.30.0/24"]
}

# -------------------------
# West Europe - ManufacturingVnet
# -------------------------
resource "azurerm_virtual_network" "mfg_vnet" {
  name                = "ManufacturingVnet"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.30.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "mfg_systems_subnet" {
  name                 = "ManufacturingSystemsSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mfg_vnet.name
  address_prefixes     = ["10.30.10.0/24"]
}

resource "azurerm_subnet" "sensor1_subnet" {
  name                 = "SensorSubnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mfg_vnet.name
  address_prefixes     = ["10.30.20.0/24"]
}

resource "azurerm_subnet" "sensor2_subnet" {
  name                 = "SensorSubnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mfg_vnet.name
  address_prefixes     = ["10.30.21.0/24"]
}

resource "azurerm_subnet" "sensor3_subnet" {
  name                 = "SensorSubnet3"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.mfg_vnet.name
  address_prefixes     = ["10.30.22.0/24"]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.40.0/26"]
}

