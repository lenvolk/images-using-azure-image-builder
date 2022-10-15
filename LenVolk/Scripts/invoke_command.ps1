
$ResourceGroup = "imageBuilderRG"
$hostPool = "Lab1HP"
$location = "eastus2"

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
# (Get-Command ./AADextention.ps1).Parameters
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{ResourceGroup = "lab1hprg";location = "eastus"} `
        -ScriptPath '.\AADextention.ps1'
}

