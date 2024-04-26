# Ref: https://learn.microsoft.com/en-us/azure/role-based-access-control/transfer-subscription#step-1-prepare-for-the-transfer

# AZ CLI
## az cloud set --name AzureUSGovernment
## az cloud set --name AzureCloud
az login --only-show-errors -o table --query Dummy
az account set -s DemoSub
# az logout

az extension list
az extension update --name resource-graph --allow-preview true

az role assignment list --all --include-inherited --output tsv > roleassignments.tsv

az role definition list --custom-role-only true --output json --query '[].{roleName:roleName, roleType:roleType}'

az role definition list --name "Azure Image Builder Image v3" > customrolenameAIBv3.json

az ad sp list --all --filter "servicePrincipalType eq 'ManagedIdentity'"

az identity list

az keyvault show