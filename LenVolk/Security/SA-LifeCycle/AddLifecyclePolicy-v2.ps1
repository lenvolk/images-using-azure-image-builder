# Ref
# https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-policy-configure?tabs=azure-powershell
# https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview?tabs=template#examples
# Example1 https://learn.microsoft.com/en-us/powershell/module/az.storage/add-azstorageaccountmanagementpolicyaction?view=azps-10.1.0#example-1-creates-a-managementpolicy-action-group-object-with-4-actions-then-add-it-to-a-management-policy-rule-and-set-to-a-storage-account
# https://www.jorgebernhardt.com/lifecycle-management-policy-azure-powershell/

$subscription = "DemoSub"
Connect-AzAccount -Subscription $subscription 
Set-AzContext -Subscription $subscription

# Initialize these variables with your values.
$resourceGroupName = "TestSA_PE"
$storageAccountName = "testsapevolk"

Enable-AzStorageBlobLastAccessTimeTracking  -ResourceGroupName $resourceGroupName `
    -StorageAccountName $storageAccountName `
    -PassThru

# Check if there is already a policy
Get-AzStorageAccountManagementPolicy `
    -ResourceGroupName $resourceGroupName `
    -StorageAccountName $storageAccountName `
    | Select-Object Rules, StorageAccountName

# Create a new filter
$filter = New-AzStorageAccountManagementPolicyFilter `
    -BlobType blockBlob

# Create an Action Group object    
$action = Add-AzStorageAccountManagementPolicyAction `
    -BaseBlobAction TierToCool `
    -DaysAfterLastAccessTimeGreaterThan 90 `
    -EnableAutoTierToHotFromCool

$action = Add-AzStorageAccountManagementPolicyAction `
    -SnapshotAction Delete `
    -daysAfterCreationGreaterThan 180 `
    -InputObject $action
    

$rule = New-AzStorageAccountManagementPolicyRule `
    -Name MyDemoPolicyRule `
    -Filter $filter `
    -Action $action
    
Set-AzStorageAccountManagementPolicy `
    -ResourceGroupName $resourceGroupName `
    -StorageAccountName $storageAccountName `
    -Rule $rule
    