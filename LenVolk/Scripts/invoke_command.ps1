
param (
    [string]$ResourceGroup,
    [string]$hostPool,
    [string]$location  
)

$ResourceGroup = "lab1hprg"
$hostPool = "Lab1HP"
$location = "eastus"

# $RegistrationToken = New-AzWvdRegistrationInfo -ResourceGroupName $ResourceGroup -HostPoolName $hostPool -ExpirationTime $((get-date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))
# $RegistrationToken = Get-AzWvdRegistrationInfo -ResourceGroupName $ResourceGroup -HostPoolName $hostPool
###################################
$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# ForEach-Object -Parallel
# req PS 7 
# iex "&amp; { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId RunPowerShellScript `
        -ScriptPath ./fslogix_regkey.ps1
}

# AAD Join
$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId RunPowerShellScript `
        -Parameter @{arg1 = "$_.ResourceGroupName";arg2 = "$_.Name";arg3 = "$location"} `
        -ScriptPath ./AADextention.ps1
}