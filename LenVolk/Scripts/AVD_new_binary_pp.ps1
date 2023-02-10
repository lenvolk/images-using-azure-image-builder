
param (
    [string]$VMresourceGroup,
    [string]$SAresourceGroup,
    [string]$storageAccount,
    [string]$container,
    [string]$blob
)

# $storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $SAresourceGroup -Name $storageAccount).Value[0]
# $Context = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageAccountKey
# $blobUri = (Get-AzStorageBlob -blob $blob -Container $container -Context $context).ICloudBlob.uri.AbsoluteUri
# $startTime = (Get-Date).AddMinutes(-15)
# $endTime = $startTime.AddHours(3.15)
# $sasToken = New-AzStorageBlobSASToken -Container $container -Blob $blob -Permission r -StartTime $startTime -ExpiryTime $endTime -Context $context

# Write-Host `
#     -ForegroundColor Yellow `
#     -BackgroundColor Green `
#     "################################"
# write-host "VMresourceGroup set to: $VMresourceGroup"
# write-host "SAresourceGroup set to: $SAresourceGroup"
# write-host "storageAccount set to: $storageAccount"
# write-host "container set to: $container"
# write-host "blob set to: $blob"
# write-host "****sasToken set to: $sasToken"


$RunningVMs = (get-azvm -ResourceGroupName $VMresourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
Write-Host `
    -ForegroundColor Yellow `
    -BackgroundColor Green `
    " ****************** Running VMS are: $RunningVMs | select name"

Write-Host `
    -ForegroundColor Yellow `
    -BackgroundColor Green `
    "############### Running find and Replace #################"

$RunFilePath = "$env:BUILD_SOURCESDIRECTORY/wvd/hp_pipeline_ops/wvd_new_binary.ps1"

# Update the runscript
# ((Get-Content -path $RunFilePath -Raw) -replace '<__param1__>', $blobUri) | Set-Content -Path $RunFilePath
# ((Get-Content -path $RunFilePath -Raw) -replace '<__param2__>', $sasToken) | Set-Content -Path $RunFilePath
# ((Get-Content -path $RunFilePath -Raw) -replace '<__param3__>', $blob) | Set-Content -Path $RunFilePath

((Get-Content -path $RunFilePath -Raw) -replace '<__param1__>', $storageAccount) | Set-Content -Path $RunFilePath
((Get-Content -path $RunFilePath -Raw) -replace '<__param2__>', $container) | Set-Content -Path $RunFilePath
((Get-Content -path $RunFilePath -Raw) -replace '<__param3__>', $blob) | Set-Content -Path $RunFilePath

# Write-Host `
#     -ForegroundColor Yellow `
#     -BackgroundColor Green `
#     "############### validating replaced params #################"

# type $RunFilePath  

Write-Host `
    -ForegroundColor Yellow `
    -BackgroundColor Green `
    "############### Executing VM RUN Command #################"

$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId RunPowerShellScript `
        -ScriptPath "$env:BUILD_SOURCESDIRECTORY/wvd/hp_pipeline_ops/wvd_new_binary.ps1"
}
