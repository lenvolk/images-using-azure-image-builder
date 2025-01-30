# Ref https://stackoverflow.com/questions/65669597/list-all-storage-accounts-and-containers-in-aure-w-powershell
$subscription = "DemoSub"

Connect-AzAccount -Subscription $subscription 
Set-AzContext -Subscription $subscription
#
az login --only-show-errors -o table --query Dummy
az account set -s $Subscription

##################################################
# Gather storage account information 
#     across all subscriptions
##################################################

$SubscriptionNames= "DemoSub"

##################################################
#     SA lifecycle policy 
#     across all subscriptions
##################################################


# Loop through each subscription
foreach ($SubscriptionName in $SubscriptionNames) {

# Set context to the subscription
Select-AzSubscription -SubscriptionId $SubscriptionName | Out-Null
$context = Get-AzContext
Write-Host "The subscription context is set to: $($context.Name)`n"
$storageAccounts = Get-AzResource -ResourceType 'Microsoft.Storage/storageAccounts' 
Write-Host "Storage Account Names are: $($storageAccounts.Name)`n"

foreach ($storageAccount in $storageAccounts) {

    Enable-AzStorageBlobLastAccessTimeTracking  -ResourceGroupName $storageAccount.ResourceGroupName `
    -StorageAccountName $storageAccount.Name `
    -PassThru

    az storage account management-policy create `
    --account-name $storageAccount.Name `
    --resource-group $storageAccount.ResourceGroupName `
    --policy .\policy.json
}

}


# az storage account management-policy show --account-name "testsapevolk" --resource-group "TestSA_PE"