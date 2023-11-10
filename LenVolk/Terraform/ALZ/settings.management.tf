# Configure the management resources settings.
locals {
  configure_management_resources = {
    settings = {
      log_analytics = {
        enabled = true
        config = {
          retention_in_days                           = var.log_retention_in_days
          enable_monitoring_for_arc                   = true
          enable_monitoring_for_vm                    = true
          enable_monitoring_for_vmss                  = true
          enable_solution_for_agent_health_assessment = true
          enable_solution_for_anti_malware            = false
          enable_solution_for_azure_activity          = false
          enable_solution_for_change_tracking         = false
          enable_solution_for_service_map             = false
          enable_solution_for_sql_assessment          = false
          enable_solution_for_updates                 = false
          enable_solution_for_vm_insights             = false
          enable_sentinel                             = true
        }
      }
      security_center = {
        enabled = true
        config = {
          email_security_contact             = var.security_alerts_email_address
          enable_defender_for_acr            = true
          enable_defender_for_app_services   = false
          enable_defender_for_arm            = false
          enable_defender_for_dns            = false
          enable_defender_for_key_vault      = false
          enable_defender_for_kubernetes     = false
          enable_defender_for_oss_databases  = false
          enable_defender_for_servers        = true
          enable_defender_for_sql_servers    = false
          enable_defender_for_sql_server_vms = false
          enable_defender_for_storage        = true
        }
      }
    }

    location = var.management_resources_location
    tags     = var.management_resources_tags
    advanced = null
  }
}
