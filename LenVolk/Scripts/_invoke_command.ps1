
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
        -CommandId 'RunPowerShellScript' `
        -ScriptPath ./fslogix_regkey.ps1
}

# Testing passing parameters to the VM's PS script
$ResourceGroup = "lab1hprg"
$location = "eastus"
$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# (Get-Command ./AADextention.ps1).Parameters
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{ResourceGroup = $using:ResourceGroup;location = $using:location} `
        -ScriptPath '.\param_invoke.ps1'
}


# Adding AVD agents to VMs
$VMRG = "imageBuilderRG"
$HPRG = "AADJoinedAVD"
$HPName = "AADJoined"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RegistrationToken = (New-AzWvdRegistrationInfo -ResourceGroupName $HPRG -HostPoolName $HPName -ExpirationTime $((get-date).ToUniversalTime().AddHours(3).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))).Token
# $RegistrationToken = Get-AzWvdRegistrationInfo -ResourceGroupName $HPRG -HostPoolName $HPName
$RunFilePath = '.\hostpool_vms.ps1'
#((Get-Content -path $RunFilePath -Raw) -replace '<__param1__>', $RegistrationToken.Token) | Set-Content -Path $RunFilePath
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{HPRegToken = $using:RegistrationToken} `
        -ScriptPath '.\hostpool_vms.ps1'
}