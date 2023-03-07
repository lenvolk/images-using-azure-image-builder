az account list -o tsv --query [].name
az account show -o tsv --query name
# Obtain the subscription id 
$subId = $(az account show -o tsv --query id)
# Assign the current logged in user to the subscription owner permissions at 
# the tenant root level to manage management groups

#$currentUserObjId = $(az ad signed-in-user show -o tsv --query objectId)
$currentUserObjId = az ad signed-in-user show --query id --output tsv

az account show -otable

az role assignment create --scope '/' --role 'Owner' --assignee-object-id $currentUserObjId --verbose
# Create the management group names
$mgNameOrg='Contoso-MG'
$mgNameDev='Contoso-Non-Production-MG'
$mgNamePrd='Contoso-Production-MG'
# Create the managment group hierarchy based on the variable names assigned above 
az account management-group create --name $mgNameOrg --display-name $mgNameOrg --verbose
az account management-group create --name $mgNameDev --parent $mgNameOrg --verbose
az account management-group create --name $mgNamePrd --parent $mgNameOrg --verbose
# Place the POC subscription into the development management group.
# You may have to press a final (Enter) after the last line below.
az account management-group subscription add --name $mgNameDev --subscription $subId --verbose
