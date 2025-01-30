
$RGName = "imageBuilderRG"
$SAName = "imagesaaad"

Get-AzStorageAccount -ResourceGroupName $RGName -Name $SAName -IncludeGeoReplicationStats
Invoke-AzStorageAccountFailover -ResourceGroupName $RGName -Name $SAName