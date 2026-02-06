# key-vault.tf

# -------------------------
# Get current Azure context
# -------------------------
data "azurerm_client_config" "current" {}

# -------------------------
# Random suffix for globally unique KV name
# -------------------------
resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

# -------------------------
# Key Vault
# -------------------------
resource "azurerm_key_vault" "lab_kv" {
  name                       = "contoso-kv-${random_string.kv_suffix.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Allow VMs to access via managed identity
  enable_rbac_authorization = false

  tags = var.tags
}

# -------------------------
# Access Policy - Your Admin Access
# -------------------------
resource "azurerm_key_vault_access_policy" "admin" {
  key_vault_id = azurerm_key_vault.lab_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover"
  ]
}

# -------------------------
# Access Policy - Ansible VM Managed Identity
# -------------------------
resource "azurerm_key_vault_access_policy" "ansible_vm" {
  key_vault_id = azurerm_key_vault.lab_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.ansible_vm.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List",
    "Set"  # Ansible VM needs to write its public key
  ]

  depends_on = [azurerm_linux_virtual_machine.ansible_vm]
}



# -------------------------
# Output Key Vault name for reference
# -------------------------
output "key_vault_name" {
  value       = azurerm_key_vault.lab_kv.name
  description = "Key Vault name"
}