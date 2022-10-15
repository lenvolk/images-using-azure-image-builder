# BGInfo
$ResourceGroup = "imageBuilderRG"
$location = "eastus2"

$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# (Get-Command ./BGInfo.ps1).Parameters
$RunningVMs | ForEach-Object -Parallel {
    Set-AzVMBgInfoExtension `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -Name "BGInfo" `
        -TypeHandlerVersion "2.1" `
        -Location $_.Location
}
