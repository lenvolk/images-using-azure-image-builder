# Ref https://www.jorgebernhardt.com/lifecycle-management-policy-azure-cli/

$subscription = "DemoSub"

# Connect-AzAccount -Subscription $subscription 
# Set-AzContext -Subscription $subscription
# #
az login --only-show-errors -o table --query Dummy
az account set -s $Subscription



# Initialize these variables with your values.
$rgName = "TestSA_PE"
$accountName = "testsapevolk"


az storage account management-policy create `
--account-name $accountName `
--resource-group $rgName `
--policy .\policy.json

# # validation
# az storage account management-policy show `
# --account-name $accountName `
# --resource-group $rgName


