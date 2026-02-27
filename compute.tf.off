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
# Database Server - Network Interface
# -------------------------
resource "azurerm_network_interface" "db_nic" {
  name                = "db-server-nic"
  location            = azurerm_virtual_network.core_vnet.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.database_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# -------------------------
# Ubuntu Database Server VM
# -------------------------
resource "azurerm_linux_virtual_machine" "db_vm" {
  name                = "DatabaseServer-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_virtual_network.core_vnet.location
  size                = "Standard_B2s"
  admin_username      = "azure_user"

  network_interface_ids = [
    azurerm_network_interface.db_nic.id,
  ]

  disable_password_authentication = true

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
# Auto-register Database VM in Ansible inventory
# -------------------------
resource "null_resource" "register_db_vm" {
  depends_on = [
    azurerm_linux_virtual_machine.db_vm,
    azurerm_linux_virtual_machine.ansible_vm
  ]

  triggers = {
    db_vm_name = azurerm_linux_virtual_machine.db_vm.name
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
      "grep -qxF '${lower(azurerm_linux_virtual_machine.db_vm.name)}.azure.poms.tech ansible_user=azure_user' /home/azure_user/ansible/inventory.ini || echo '${lower(azurerm_linux_virtual_machine.db_vm.name)}.azure.poms.tech ansible_user=azure_user' >> /home/azure_user/ansible/inventory.ini",
      "echo 'Registered ${azurerm_linux_virtual_machine.db_vm.name} (${lower(azurerm_linux_virtual_machine.db_vm.name)}.azure.poms.tech) in Ansible inventory'"
    ]
  }
}

# =========================
# Manufacturing VNet VMs (West Europe)
# =========================

# -------------------------
# MfgServer-01 - ManufacturingSystemsSubnet
# -------------------------
resource "azurerm_network_interface" "mfg_nic" {
  name                = "mfg-server-nic"
  location            = azurerm_virtual_network.mfg_vnet.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mfg_systems_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "mfg_vm" {
  name                = "MfgServer-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_virtual_network.mfg_vnet.location
  size                = "Standard_B2s"
  admin_username      = "azure_user"

  network_interface_ids = [
    azurerm_network_interface.mfg_nic.id,
  ]

  disable_password_authentication = true

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

resource "null_resource" "register_mfg_vm" {
  depends_on = [
    azurerm_linux_virtual_machine.mfg_vm,
    azurerm_linux_virtual_machine.ansible_vm
  ]

  triggers = {
    vm_name = azurerm_linux_virtual_machine.mfg_vm.name
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
      "grep -qxF '${lower(azurerm_linux_virtual_machine.mfg_vm.name)}.azure.poms.tech ansible_user=azure_user' /home/azure_user/ansible/inventory.ini || echo '${lower(azurerm_linux_virtual_machine.mfg_vm.name)}.azure.poms.tech ansible_user=azure_user' >> /home/azure_user/ansible/inventory.ini",
      "echo 'Registered ${azurerm_linux_virtual_machine.mfg_vm.name} (${lower(azurerm_linux_virtual_machine.mfg_vm.name)}.azure.poms.tech) in Ansible inventory'"
    ]
  }
}

# -------------------------
# SensorServer-01 - SensorSubnet1
# -------------------------
resource "azurerm_network_interface" "sensor1_nic" {
  name                = "sensor1-server-nic"
  location            = azurerm_virtual_network.mfg_vnet.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sensor1_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "sensor1_vm" {
  name                = "SensorServer-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_virtual_network.mfg_vnet.location
  size                = "Standard_B2s"
  admin_username      = "azure_user"

  network_interface_ids = [
    azurerm_network_interface.sensor1_nic.id,
  ]

  disable_password_authentication = true

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

resource "null_resource" "register_sensor1_vm" {
  depends_on = [
    azurerm_linux_virtual_machine.sensor1_vm,
    azurerm_linux_virtual_machine.ansible_vm
  ]

  triggers = {
    vm_name = azurerm_linux_virtual_machine.sensor1_vm.name
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
      "grep -qxF '${lower(azurerm_linux_virtual_machine.sensor1_vm.name)}.azure.poms.tech ansible_user=azure_user' /home/azure_user/ansible/inventory.ini || echo '${lower(azurerm_linux_virtual_machine.sensor1_vm.name)}.azure.poms.tech ansible_user=azure_user' >> /home/azure_user/ansible/inventory.ini",
      "echo 'Registered ${azurerm_linux_virtual_machine.sensor1_vm.name} (${lower(azurerm_linux_virtual_machine.sensor1_vm.name)}.azure.poms.tech) in Ansible inventory'"
    ]
  }
}

# -------------------------
# SensorServer-02 - SensorSubnet2
# -------------------------
resource "azurerm_network_interface" "sensor2_nic" {
  name                = "sensor2-server-nic"
  location            = azurerm_virtual_network.mfg_vnet.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sensor2_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "sensor2_vm" {
  name                = "SensorServer-02"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_virtual_network.mfg_vnet.location
  size                = "Standard_B2s"
  admin_username      = "azure_user"

  network_interface_ids = [
    azurerm_network_interface.sensor2_nic.id,
  ]

  disable_password_authentication = true

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

resource "null_resource" "register_sensor2_vm" {
  depends_on = [
    azurerm_linux_virtual_machine.sensor2_vm,
    azurerm_linux_virtual_machine.ansible_vm
  ]

  triggers = {
    vm_name = azurerm_linux_virtual_machine.sensor2_vm.name
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
      "grep -qxF '${lower(azurerm_linux_virtual_machine.sensor2_vm.name)}.azure.poms.tech ansible_user=azure_user' /home/azure_user/ansible/inventory.ini || echo '${lower(azurerm_linux_virtual_machine.sensor2_vm.name)}.azure.poms.tech ansible_user=azure_user' >> /home/azure_user/ansible/inventory.ini",
      "echo 'Registered ${azurerm_linux_virtual_machine.sensor2_vm.name} (${lower(azurerm_linux_virtual_machine.sensor2_vm.name)}.azure.poms.tech) in Ansible inventory'"
    ]
  }
}

# -------------------------
# SensorServer-03 - SensorSubnet3
# -------------------------
resource "azurerm_network_interface" "sensor3_nic" {
  name                = "sensor3-server-nic"
  location            = azurerm_virtual_network.mfg_vnet.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sensor3_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "sensor3_vm" {
  name                = "SensorServer-03"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_virtual_network.mfg_vnet.location
  size                = "Standard_B2s"
  admin_username      = "azure_user"

  network_interface_ids = [
    azurerm_network_interface.sensor3_nic.id,
  ]

  disable_password_authentication = true

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

resource "null_resource" "register_sensor3_vm" {
  depends_on = [
    azurerm_linux_virtual_machine.sensor3_vm,
    azurerm_linux_virtual_machine.ansible_vm
  ]

  triggers = {
    vm_name = azurerm_linux_virtual_machine.sensor3_vm.name
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
      "grep -qxF '${lower(azurerm_linux_virtual_machine.sensor3_vm.name)}.azure.poms.tech ansible_user=azure_user' /home/azure_user/ansible/inventory.ini || echo '${lower(azurerm_linux_virtual_machine.sensor3_vm.name)}.azure.poms.tech ansible_user=azure_user' >> /home/azure_user/ansible/inventory.ini",
      "echo 'Registered ${azurerm_linux_virtual_machine.sensor3_vm.name} (${lower(azurerm_linux_virtual_machine.sensor3_vm.name)}.azure.poms.tech) in Ansible inventory'"
    ]
  }
}

# =========================
# Research VNet VM (Southeast Asia)
# =========================

# -------------------------
# ResearchServer-01 - ResearchSystemSubnet
# -------------------------
resource "azurerm_network_interface" "research_nic" {
  name                = "research-server-nic"
  location            = azurerm_virtual_network.research_vnet.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.research_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "research_vm" {
  name                = "ResearchServer-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_virtual_network.research_vnet.location
  size                = "Standard_B2s"
  admin_username      = "azure_user"

  network_interface_ids = [
    azurerm_network_interface.research_nic.id,
  ]

  disable_password_authentication = true

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

resource "null_resource" "register_research_vm" {
  depends_on = [
    azurerm_linux_virtual_machine.research_vm,
    azurerm_linux_virtual_machine.ansible_vm
  ]

  triggers = {
    vm_name = azurerm_linux_virtual_machine.research_vm.name
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
      "grep -qxF '${lower(azurerm_linux_virtual_machine.research_vm.name)}.azure.poms.tech ansible_user=azure_user' /home/azure_user/ansible/inventory.ini || echo '${lower(azurerm_linux_virtual_machine.research_vm.name)}.azure.poms.tech ansible_user=azure_user' >> /home/azure_user/ansible/inventory.ini",
      "echo 'Registered ${azurerm_linux_virtual_machine.research_vm.name} (${lower(azurerm_linux_virtual_machine.research_vm.name)}.azure.poms.tech) in Ansible inventory'"
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

output "db_vm_private_ip" {
  value       = azurerm_network_interface.db_nic.private_ip_address
  description = "Private IP of Database Server"
}

output "db_vm_fqdn" {
  value       = "${azurerm_linux_virtual_machine.db_vm.name}.azure.poms.tech"
  description = "DNS name in private DNS zone"
}

output "mfg_vm_private_ip" {
  value       = azurerm_network_interface.mfg_nic.private_ip_address
  description = "Private IP of Manufacturing Server"
}

output "mfg_vm_fqdn" {
  value       = "${azurerm_linux_virtual_machine.mfg_vm.name}.azure.poms.tech"
  description = "DNS name in private DNS zone"
}

output "sensor1_vm_private_ip" {
  value       = azurerm_network_interface.sensor1_nic.private_ip_address
  description = "Private IP of Sensor Server 1"
}

output "sensor1_vm_fqdn" {
  value       = "${azurerm_linux_virtual_machine.sensor1_vm.name}.azure.poms.tech"
  description = "DNS name in private DNS zone"
}

output "sensor2_vm_private_ip" {
  value       = azurerm_network_interface.sensor2_nic.private_ip_address
  description = "Private IP of Sensor Server 2"
}

output "sensor2_vm_fqdn" {
  value       = "${azurerm_linux_virtual_machine.sensor2_vm.name}.azure.poms.tech"
  description = "DNS name in private DNS zone"
}

output "sensor3_vm_private_ip" {
  value       = azurerm_network_interface.sensor3_nic.private_ip_address
  description = "Private IP of Sensor Server 3"
}

output "sensor3_vm_fqdn" {
  value       = "${azurerm_linux_virtual_machine.sensor3_vm.name}.azure.poms.tech"
  description = "DNS name in private DNS zone"
}

output "research_vm_private_ip" {
  value       = azurerm_network_interface.research_nic.private_ip_address
  description = "Private IP of Research Server"
}

output "research_vm_fqdn" {
  value       = "${azurerm_linux_virtual_machine.research_vm.name}.azure.poms.tech"
  description = "DNS name in private DNS zone"
}