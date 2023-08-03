# Ref
# https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-policy-configure?tabs=azure-powershell
# https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview?tabs=template#examples
# Example1 https://learn.microsoft.com/en-us/powershell/module/az.storage/add-azstorageaccountmanagementpolicyaction?view=azps-10.1.0#example-1-creates-a-managementpolicy-action-group-object-with-4-actions-then-add-it-to-a-management-policy-rule-and-set-to-a-storage-account
# Explanation of the policy https://www.jorgebernhardt.com/lifecycle-management-policy-azure-powershell/

$subscription = "DemoSub"
Connect-AzAccount -Subscription $subscription 
Set-AzContext -Subscription $subscription

# Initialize these variables with your values.
$rgName = "TestSA_PE"
$accountName = "testsapevolk"

Enable-AzStorageBlobLastAccessTimeTracking  -ResourceGroupName $rgName `
    -StorageAccountName $accountName `
    -PassThru


$ExistingPolicy = Get-AzStorageAccountManagementPolicy `
    -ResourceGroupName $rgName `
    -StorageAccountName $accountName `
    | Select-Object Rules, StorageAccountName
 
if ($ExistingPolicy.Rules.Name -eq "CostOpt") {
    Write-Host "The SA name: $($accountName) already has a policy named: $($ExistingPolicy.Rules.Name)"
}

else {

Write-Output "The SA name: $($accountName) doesn't have lifecycle policy. Creating one."
  

$action = Add-AzStorageAccountManagementPolicyAction -BaseBlobAction Delete -DaysAfterCreationGreaterThan 100
$action = Add-AzStorageAccountManagementPolicyAction -BaseBlobAction TierToArchive -daysAfterModificationGreaterThan 50  -DaysAfterLastTierChangeGreaterThan 40 -InputObject $action
$action = Add-AzStorageAccountManagementPolicyAction -BaseBlobAction TierToCool -DaysAfterLastAccessTimeGreaterThan 30  -EnableAutoTierToHotFromCool -InputObject $action
#$action = Add-AzStorageAccountManagementPolicyAction -BaseBlobAction TierToHot -DaysAfterCreationGreaterThan 100 -InputObject $action
$action = Add-AzStorageAccountManagementPolicyAction -SnapshotAction Delete -daysAfterCreationGreaterThan 100 -InputObject $action

# Create a new filter object.
$filter = New-AzStorageAccountManagementPolicyFilter `
    -BlobType blockBlob

# Create a new rule object.
$rule = New-AzStorageAccountManagementPolicyRule -Name CostOpt `
    -Action $action `
    -Filter $filter

# Create the policy.
Set-AzStorageAccountManagementPolicy -ResourceGroupName $rgName -AccountName $accountName -Rule $rule

}