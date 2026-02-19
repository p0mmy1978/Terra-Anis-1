# web-apps.tf - Azure Web Apps in 3 regions (future Traffic Manager endpoints)

# -------------------------
# Random suffix for globally unique web app names
# -------------------------
resource "random_string" "webapp_suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  webapps = {
    centralus = {
      location    = "centralus"
      region_name = "Central US"
    }
    westeurope = {
      location    = "westeurope"
      region_name = "West Europe"
    }
    southeastasia = {
      location    = "southeastasia"
      region_name = "Southeast Asia"
    }
  }
}

# -------------------------
# App Service Plans (B1 Basic, Linux)
# -------------------------
resource "azurerm_service_plan" "webapp_plan" {
  for_each            = local.webapps
  name                = "poms-asp-${each.key}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "S1"
  tags                = var.tags
}

# -------------------------
# Linux Web Apps (Node.js 18)
# -------------------------
resource "azurerm_linux_web_app" "webapp" {
  for_each            = local.webapps
  name                = "poms-web-${each.key}-${random_string.webapp_suffix.result}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.webapp_plan[each.key].id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
    always_on = true
  }

  app_settings = {
    SERVER_NAME = "poms-web-${each.key}-${random_string.webapp_suffix.result}"
    REGION      = each.value.region_name
  }

  tags = var.tags
}

# -------------------------
# Zip Deploy the Node.js app to each Web App
# -------------------------
resource "null_resource" "deploy_webapp" {
  for_each = local.webapps

  depends_on = [azurerm_linux_web_app.webapp]

  triggers = {
    app_id   = azurerm_linux_web_app.webapp[each.key].id
    code_hash = filesha256("${path.module}/webapp/server.js")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/webapp && zip -r /tmp/webapp-${each.key}.zip . && az webapp deploy --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_linux_web_app.webapp[each.key].name} --src-path /tmp/webapp-${each.key}.zip --type zip"
  }
}

# -------------------------
# Custom Domain Binding (Traffic Manager custom domain)
# -------------------------
resource "azurerm_app_service_custom_hostname_binding" "poms_custom_domain" {
  for_each            = local.webapps
  hostname            = "poms.trafficmanager.poms.tech"
  app_service_name    = azurerm_linux_web_app.webapp[each.key].name
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [null_resource.deploy_webapp]
}

# -------------------------
# Outputs
# -------------------------
output "webapp_urls" {
  value = {
    for key, webapp in azurerm_linux_web_app.webapp :
    key => "https://${webapp.default_hostname}"
  }
  description = "URLs for the Web Apps in each region"
}
