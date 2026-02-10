# nsg.tf

# -------------------------
# Network Security Group for Ansible VM
# -------------------------
resource "azurerm_network_security_group" "ansible_nsg" {
  name                = "ansible-vm-nsg"
  location            = azurerm_virtual_network.core_vnet.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh-from-home"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "20.53.196.138/32"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# -------------------------
# Associate NSG with NIC
# -------------------------
resource "azurerm_network_interface_security_group_association" "ansible_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.ansible_nic.id
  network_security_group_id = azurerm_network_security_group.ansible_nsg.id
}
