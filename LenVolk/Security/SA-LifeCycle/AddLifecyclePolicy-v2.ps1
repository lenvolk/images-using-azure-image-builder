# Ref
# https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-policy-configure?tabs=azure-powershell
# https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview?tabs=template#examples
# Example1 https://learn.microsoft.com/en-us/powershell/module/az.storage/add-azstorageaccountmanagementpolicyaction?view=azps-10.1.0#example-1-creates-a-managementpolicy-action-group-object-with-4-actions-then-add-it-to-a-management-policy-rule-and-set-to-a-storage-account
# Explanation of the policy https://www.jorgebernhardt.com/lifecycle-management-policy-azure-powershell/

# $subscription = "DemoSub"
# Connect-AzAccount -Subscription $subscription 
# Set-AzContext -Subscription $subscription

##################################################
# Gather storage account information 
#     across all subscriptions
##################################################

# To output a list of all your subscription IDs using Resource Graph you can use 
# ref https://www.geeksforgeeks.org/microsoft-azure-get-azure-subscription-details-using-resource-graph-query/
Install-Module Az.ResourceGraph -force
$SubscriptionNames = Search-AzGraph -Query "resourcecontainers | where type=='microsoft.resources/subscriptions' | project SubscriptionName=name, subscriptionId, tenantId"

#$SubscriptionNames= "DemoSub"

##################################################
#     SA lifecycle policy 
#     across all subscriptions
##################################################


# Loop through each subscription
foreach ($SubscriptionName in $SubscriptionNames.subscriptionname) {

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
    
        $ExistingPolicy = Get-AzStorageAccountManagementPolicy `
        -ResourceGroupName $storageAccount.ResourceGroupName `
        -StorageAccountName $storageAccount.Name `
        | Select-Object Rules, StorageAccountName `
        -ErrorAction Ignore

        if ($ExistingPolicy.Rules.Name -eq "CostOpt") {
            Write-Host "The SA name: $($storageAccount.Name) already has a policy named: $($ExistingPolicy.Rules.Name)"
        }
        
        else {

            Write-Output "The SA name: $($storageAccount.Name) doesn't have lifecycle policy."
                $confirmation = Read-Host "Would you like to creat it? Y or N"
                if ($confirmation -ne 'y')
                {
                    Write-Output "exiting"
                    exit
                }
        
        Write-Output "Adding lifecycle policy for SA name: $($storageAccount.Name)"
          
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
        Set-AzStorageAccountManagementPolicy -ResourceGroupName $storageAccount.ResourceGroupName -AccountName $storageAccount.Name -Rule $rule
        
        }

    }
    
}