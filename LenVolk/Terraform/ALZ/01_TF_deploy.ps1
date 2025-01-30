# Ref https://github.com/Azure/terraform-azurerm-caf-enterprise-scale/wiki/%5BExamples%5D-Deploy-Custom-Landing-Zone-Archetypes
# caf-enterprise-scale module https://registry.terraform.io/modules/Azure/caf-enterprise-scale/azurerm/latest

# AZ CLI
# az cloud set --name AzureUSGovernment
# az cloud set --name AzureCloud
az login --only-show-errors -o table --query Dummy
# $subscription = "On-Prem"
# az account set -s $subscription



# terraform init
# terraform plan
# terraform apply -auto-approve -parallelism 50