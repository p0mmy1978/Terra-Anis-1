# compute.tf

# -------------------------
# Wait for cloud-init to finish on Ansible VM
# (ensures SSH key is uploaded to Key Vault)
# -------------------------
resource "null_resource" "wait_for_cloud_init" {
  depends_on = [
    azurerm_linux_virtual_machine.ansible_vm,
    azurerm_key_vault_access_policy.ansible_vm
  ]

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.ansible_pip.ip_address
    user        = "azure_user"
    private_key = file("${path.module}/keys/ansible_rsa")
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait",
      "echo 'Cloud-init finished.'"
    ]
  }
}

# -------------------------
# Get Ansible public key from Key Vault
# -------------------------
data "azurerm_key_vault_secret" "ansible_pubkey" {
  name         = "ansible-public-key"
  key_vault_id = azurerm_key_vault.lab_kv.id

  depends_on = [
    null_resource.wait_for_cloud_init
  ]
}

# -------------------------
# Network Interface
# -------------------------
resource "azurerm_network_interface" "web_nic" {
  name                = "web-server-nic"
  location            = azurerm_virtual_network.core_vnet.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# -------------------------
# Ubuntu Web Server VM
# -------------------------
resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "WebServer-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_virtual_network.core_vnet.location
  size                = "Standard_B2s"
  admin_username      = "azure_user"

  network_interface_ids = [
    azurerm_network_interface.web_nic.id,
  ]

  disable_password_authentication = true

  # Use Ansible's public key from Key Vault
  admin_ssh_key {
    username   = "azure_user"
    public_key = data.azurerm_key_vault_secret.ansible_pubkey.value
  }

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
# Auto-register VM in Ansible inventory
# -------------------------
resource "null_resource" "register_web_vm" {
  depends_on = [
    azurerm_linux_virtual_machine.web_vm,
    azurerm_linux_virtual_machine.ansible_vm
  ]

  # Re-run if the web VM's name changes
  triggers = {
    web_vm_name = azurerm_linux_virtual_machine.web_vm.name
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.ansible_pip.ip_address
    user        = "azure_user"
    private_key = file("${path.module}/keys/ansible_rsa")
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # Add the web server to the inventory using DNS name
      "grep -qxF '${lower(azurerm_linux_virtual_machine.web_vm.name)}.azure.poms.tech ansible_user=azure_user' /home/azure_user/ansible/inventory.ini || echo '${lower(azurerm_linux_virtual_machine.web_vm.name)}.azure.poms.tech ansible_user=azure_user' >> /home/azure_user/ansible/inventory.ini",
      "echo 'Registered ${azurerm_linux_virtual_machine.web_vm.name} (${lower(azurerm_linux_virtual_machine.web_vm.name)}.azure.poms.tech) in Ansible inventory'"
    ]
  }
}

# -------------------------
# Outputs
# -------------------------
output "web_vm_private_ip" {
  value       = azurerm_network_interface.web_nic.private_ip_address
  description = "Private IP of Web Server"
}

output "web_vm_fqdn" {
  value       = "${azurerm_linux_virtual_machine.web_vm.name}.azure.poms.tech"
  description = "DNS name in private DNS zone"
}