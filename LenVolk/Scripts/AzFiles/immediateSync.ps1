#Ref  https://learn.microsoft.com/en-us/powershell/module/az.storagesync/invoke-azstoragesyncchangedetection?view=azps-11.4.0

$RGName = "FailOverCluster"

$SAName = "failoverclustersa"

$SyncName = "AFS01"  # Name of the StorageSyncService

$SyncGrpName = "office-share-01"

$CloudEndpointName = Get-AzStorageSyncCloudEndpoint -ResourceGroupName $RGName -StorageSyncServiceName $SyncName -SyncGroupName $SyncGrpName

Invoke-AzStorageSyncChangeDetection -ResourceGroupName $RGName -StorageSyncServiceName $SyncName -SyncGroupName $SyncGrpName -CloudEndpointName $CloudEndpointName.CloudEndpointName -Path "OfficeShares\Marketing"