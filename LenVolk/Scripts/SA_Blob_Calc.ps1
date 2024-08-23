# Login to Azure
Connect-AzAccount

# Get the storage account context
$storageAccount = Get-AzStorageAccount -ResourceGroupName "<ResourceGroupName>" -Name "<StorageAccountName>"
$ctx = $storageAccount.Context

# List the containers
$containers = Get-AzStorageContainer -Context $ctx

# Iterate through containers and get metrics
foreach ($container in $containers) {
    $metrics = Get-AzStorageBlob -Container $container.Name -Context $ctx | Measure-Object
    Write-Output "Container: $($container.Name) has $($metrics.Count) transactions"
}

