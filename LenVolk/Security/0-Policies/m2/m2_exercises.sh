# Add the blueprint extension
az extension add --name blueprint

#Log into Azure with CLI
az login
az account set --subscription "MSDN-SUB"

cd ./blueprint

# Create the blueprint object
az blueprint create \
   --name 'Default-Setup' \
   --parameters blueprint.json \
   --management-group "Contoso" \
   --target-scope subscription

az blueprint resource-group add \
   --blueprint-name 'Default-Setup' \
   --artifact-name 'Networking' \
   --description 'Resource group for networking resources.' \
   --rg-name 'Networking' \
   --management-group "Contoso"

az blueprint resource-group add \
   --blueprint-name 'Default-Setup' \
   --artifact-name 'Security' \
   --description 'Resource group for security resources.' \
   --rg-name 'Security' \
   --management-group "Contoso"

az blueprint artifact role create \
  --blueprint-name 'Default-Setup' \
  --management-group "Contoso" \
  --artifact-name 'NetRBAC' \
  --role-definition-id "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" \
  --principal-ids "[parameters('networkOwners')]" \
  --resource-group-art 'Networking'

az blueprint artifact role create \
  --blueprint-name 'Default-Setup' \
  --management-group "Contoso" \
  --artifact-name 'SecRBAC' \
  --role-definition-id "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635" \
  --principal-ids "[parameters('securityOwners')]" \
  --resource-group-art 'Security'

az blueprint artifact role create \
  --blueprint-name 'Default-Setup' \
  --management-group "Contoso" \
  --artifact-name 'ContribRBAC' \
  --role-definition-id "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c" \
  --principal-ids "[parameters('subscriptionContributors')]"

az blueprint artifact policy create \
  --blueprint-name 'Default-Setup' \
  --management-group "Contoso" \
  --artifact-name 'envPolicyTags' \
  --policy-definition-id "/providers/Microsoft.Authorization/policyDefinitions/5ffd78d9-436d-4b41-a421-5baa819e3008" \
  --display-name "Environment tagging" \
  --description "Apply environment tag to all resources in the subscription" \
  --parameters envTagParams.json

az blueprint artifact policy create \
  --blueprint-name 'Default-Setup' \
  --management-group "Contoso" \
  --artifact-name 'secPolicyTags' \
  --policy-definition-id "/providers/Microsoft.Authorization/policyDefinitions/5ffd78d9-436d-4b41-a421-5baa819e3008" \
  --display-name "Security owner tag" \
  --description "Apply security owner tag to all resources in the security resource group" \
  --parameters secTagParams.json \
  --resource-group-art 'Security'

az blueprint artifact template create \
  --blueprint-name 'Default-Setup' \
  --management-group "Contoso" \
  --artifact-name 'vnetTemplate' \
  --template vnetTemplate.json \
  --parameters vnetTemplateParameters.json \
  --resource-group-art 'Networking'

az blueprint publish \
  --blueprint-name 'Default-Setup' \
  --management-group "Contoso" \
  --version 1.0