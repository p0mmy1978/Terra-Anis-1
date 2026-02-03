resource "azurerm_virtual_network_peering" "core_to_mfg" {
  name                      = "core-to-mfg"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.core_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.mfg_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic     = true
}

resource "azurerm_virtual_network_peering" "mfg_to_core" {
  name                      = "mfg-to-core"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.mfg_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.core_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic     = true
}

resource "azurerm_virtual_network_peering" "core_to_research" {
  name                      = "core-to-research"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.core_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.research_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic     = true
}

resource "azurerm_virtual_network_peering" "research_to_core" {
  name                      = "research-to-core"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.research_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.core_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic     = true
}
