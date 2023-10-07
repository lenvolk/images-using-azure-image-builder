# Ref
# https://learn.microsoft.com/en-us/azure/storage/scripts/storage-blobs-container-calculate-size-powershell
#

# $sub = Get-AzSubscription | select Name  
$sub = "DemoSub"
$sub | foreach {   
Set-AzContext -Subscription $_.Name  
$currentSub = $_.Name  
$RGs = Get-AzResourceGroup | select ResourceGroupName  
$RGs | foreach {  
$CurrentRG = $_.ResourceGroupName  
$StorageAccounts = Get-AzStorageAccount -ResourceGroupName $CurrentRG | select StorageAccountName  
$StorageAccounts | foreach {  
$StorageAccount = $_.StorageAccountName  
$CurrentSAID = (Get-AzStorageAccount -ResourceGroupName $CurrentRG -AccountName $StorageAccount).Id  
$usedCapacity = (Get-AzMetric -ResourceId $CurrentSAID -MetricName "UsedCapacity").Data  
$usedCapacityInMB = $usedCapacity.Average / 1024 / 1024  
"$StorageAccount,$usedCapacityInMB,$CurrentRG,$currentSub" >> ".\storageAccountsUsedCapacity.csv"  
}  
}  
}