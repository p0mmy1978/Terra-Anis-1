# custom-domain.tf.off - Custom Domain Binding for Traffic Manager Web Apps
#
# Pre-requisites before enabling:
#   1. DNS propagated in Hostinger:
#      - CNAME  poms.trafficmanager.poms.tech  →  <tm-profile>.trafficmanager.net
#      - TXT    asuid.poms.trafficmanager.poms.tech  →  each app's customDomainVerificationId
#        (get verification IDs with: az webapp show --name <app> --resource-group <rg> --query customDomainVerificationId)
#   2. web-apps.tf already applied (web apps must exist)
#
# To enable: rename this file to custom-domain.tf, then run terraform apply

resource "azurerm_app_service_custom_hostname_binding" "poms_custom_domain" {
  for_each            = local.webapps
  hostname            = "poms.trafficmanager.poms.tech"
  app_service_name    = azurerm_linux_web_app.webapp[each.key].name
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [null_resource.deploy_webapp]
}
