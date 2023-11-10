# Get the current client configuration from the AzureRM provider.
# This is used to populate the root_parent_id variable with the
# current Tenant ID used as the ID for the "Tenant Root Group"
# Management Group.

data "azurerm_client_config" "core" {}

# Declare the Terraform Module for Cloud Adoption Framework
# Enterprise-scale and provide a base configuration.

module "enterprise_scale" {
  source  = "Azure/caf-enterprise-scale/azurerm"
  version = "1.1.3"

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
    azurerm.management   = azurerm.management
   }

  default_location = var.default_location

  root_parent_id = data.azurerm_client_config.core.tenant_id
  root_id        = var.root_id
  root_name      = var.root_name
  library_path   = "${path.root}/lib"

  deploy_core_landing_zones = true

  deploy_management_resources = true
  subscription_id_management = var.managementSubscriptionId
  configure_management_resources = local.configure_management_resources

  deploy_identity_resources    = true
  subscription_id_identity     = var.identitySubscriptionId
  configure_identity_resources = local.configure_identity_resources

  deploy_connectivity_resources    = true
  subscription_id_connectivity     = var.connectivitySubscriptionId
  configure_connectivity_resources = local.configure_connectivity_resources

  deploy_corp_landing_zones = true
  deploy_online_landing_zones = true

  subscription_id_overrides = {
    sandboxes = ["7201ec24-998b-4283-bb78-6bbabc7f3d2d"]
    #management = []
    #root = []
  }


  custom_landing_zones = {
    "${var.root_id}-eucustomers" = {
      display_name               = "${upper(var.root_id)} EUCustomers"
      parent_management_group_id = "${var.root_id}-landing-zones"
      subscription_ids           = [ ] #["6afc5ee8-735d-463a-b70a-7e652cf2302c"]
      archetype_config = {
        archetype_id   = "eu_customer"
        parameters     = {}
        access_control = {}
      }
    }
  }
}