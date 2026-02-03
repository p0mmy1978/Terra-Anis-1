# -------------------------
# Private DNS Zone
# -------------------------

resource "azurerm_private_dns_zone" "azure_poms" {
  name                = "azure.poms.tech"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# -------------------------
# VNet Links
# -------------------------

# Hub - auto registration ON
resource "azurerm_private_dns_zone_virtual_network_link" "core_link" {
  name                  = "core-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.azure_poms.name
  virtual_network_id   = azurerm_virtual_network.core_vnet.id

  registration_enabled = true
  tags = var.tags
}

# Spoke - auto registration ON
resource "azurerm_private_dns_zone_virtual_network_link" "research_link" {
  name                  = "research-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.azure_poms.name
  virtual_network_id   = azurerm_virtual_network.research_vnet.id

  registration_enabled = true
  tags = var.tags
}

# Spoke - auto registration ON
resource "azurerm_private_dns_zone_virtual_network_link" "mfg_link" {
  name                  = "mfg-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.azure_poms.name
  virtual_network_id   = azurerm_virtual_network.mfg_vnet.id

  registration_enabled = true
  tags = var.tags
}
