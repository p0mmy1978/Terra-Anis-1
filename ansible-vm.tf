# ansible-vm.tf

# -------------------------
# Network Interface
# -------------------------
resource "azurerm_network_interface" "ansible_nic" {
  name                = "ansible-vm-nic"
  location            = azurerm_virtual_network.core_vnet.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.shared_services_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# -------------------------
# Ubuntu VM
# -------------------------
resource "azurerm_linux_virtual_machine" "ansible_vm" {
  name                = "Ansible-VM-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_virtual_network.core_vnet.location
  size                = "Standard_B2s"
  admin_username      = "azureadmin"

  network_interface_ids = [
    azurerm_network_interface.ansible_nic.id,
  ]

  admin_password                  = "plschgme123!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}

# -------------------------
# Output the private IP
# -------------------------
output "ansible_vm_private_ip" {
  value       = azurerm_network_interface.ansible_nic.private_ip_address
  description = "Private IP of Ansible VM"
}