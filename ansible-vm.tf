# ansible-vm.tf

# -------------------------
# Public IP
# -------------------------
resource "azurerm_public_ip" "ansible_pip" {
  name                = "ansible-vm-pip"
  location            = azurerm_virtual_network.core_vnet.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

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
    public_ip_address_id          = azurerm_public_ip.ansible_pip.id
  }

  tags = var.tags
}

# -------------------------
# Cloud-init configuration
# -------------------------
data "cloudinit_config" "ansible_init" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      package_update  = true
      package_upgrade = true

      packages = [
        "software-properties-common",
        "python3-pip",
        "git"
      ]

      runcmd = [
        # Add Ansible PPA and install
        "add-apt-repository --yes --update ppa:ansible/ansible",
        "apt install -y ansible",
        
        # Generate SSH key for ansible user
        "sudo -u azure_user ssh-keygen -t rsa -b 4096 -f /home/azure_user/.ssh/id_rsa -N '' -C 'ansible@azure'",
        "sudo -u azure_user chmod 600 /home/azure_user/.ssh/id_rsa",
        "sudo -u azure_user chmod 644 /home/azure_user/.ssh/id_rsa.pub",
        
        # Create ansible config directory
        "sudo -u azure_user mkdir -p /home/azure_user/ansible",
        
        # Log completion
        "echo 'Ansible installation completed' > /var/log/cloud-init-complete.log"
      ]
    })
  }
}

# -------------------------
# Ubuntu VM with SSH Key & Cloud-Init
# -------------------------
resource "azurerm_linux_virtual_machine" "ansible_vm" {
  name                = "Ansible-VM-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_virtual_network.core_vnet.location
  size                = "Standard_B2s"
  admin_username      = "azure_user"

  network_interface_ids = [
    azurerm_network_interface.ansible_nic.id,
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azure_user"
    public_key = file("${path.module}/keys/ansible_rsa.pub")
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

  custom_data = data.cloudinit_config.ansible_init.rendered

  tags = var.tags
}

# -------------------------
# Outputs
# -------------------------
output "ansible_vm_private_ip" {
  value       = azurerm_network_interface.ansible_nic.private_ip_address
  description = "Private IP of Ansible VM"
}

output "ansible_vm_public_ip" {
  value       = azurerm_public_ip.ansible_pip.ip_address
  description = "Public IP of Ansible VM"
}

output "ansible_vm_ssh_command" {
  value       = "ssh -i keys/ansible_rsa azure_user@${azurerm_public_ip.ansible_pip.ip_address}"
  description = "SSH command to connect to Ansible VM"
}
