# Ref
# https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-policy-configure?tabs=azure-powershell
# https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview?tabs=template#examples
#
$subscription = "DemoSub"
Connect-AzAccount -Subscription $subscription 
Set-AzContext -Subscription $subscription

# Initialize these variables with your values.
$rgName = "TestSA_PE"
$accountName = "testsapevolk"

Enable-AzStorageBlobLastAccessTimeTracking  -ResourceGroupName $rgName `
    -StorageAccountName $accountName `
    -PassThru


# Create a new action object.
$action1 = Add-AzStorageAccountManagementPolicyAction -BaseBlobAction Delete `
    -daysAfterModificationGreaterThan 180
Add-AzStorageAccountManagementPolicyAction -InputObject $action1 `
    -BaseBlobAction TierToArchive `
    -daysAfterModificationGreaterThan 90
Add-AzStorageAccountManagementPolicyAction -InputObject $action1 `
    -BaseBlobAction TierToCool `
    -daysAfterModificationGreaterThan 30
Add-AzStorageAccountManagementPolicyAction -InputObject $action1 `
    -SnapshotAction Delete `
    -daysAfterCreationGreaterThan 90
Add-AzStorageAccountManagementPolicyAction -InputObject $action1 `
    -BlobVersionAction TierToArchive `
    -daysAfterCreationGreaterThan 90
Add-AzStorageAccountManagementPolicyAction -InputObject $action1 `
    -BlobVersionAction TierToArchive `
    -daysAfterCreationGreaterThan 90

# # last-accessed-thirty-days-ago
# $action2 = Add-AzStorageAccountManagementPolicyAction -BaseBlobAction TierToHot `
#     -daysAfterLastAccessTimeGreaterThan 30

# Create a new filter object.
$filter = New-AzStorageAccountManagementPolicyFilter `
    -BlobType blockBlob
    #-PrefixMatch ab,cd `

# Create a new rule object.
$rule1 = New-AzStorageAccountManagementPolicyRule -Name CostOpt1 `
    -Action $action1 `
    -Filter $filter

# Create the policy.
Set-AzStorageAccountManagementPolicy -ResourceGroupName $rgName `
    -StorageAccountName $accountName `
    -Rule $rule1