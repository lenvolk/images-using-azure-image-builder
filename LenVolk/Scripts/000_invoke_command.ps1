
$ResourceGroup = "imageBuilderRG"
$hostPool = "Lab1HP"
$location = "eastus2"

###################################
$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# ForEach-Object -Parallel
# req PS 7 
# iex "&amp; { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"


##################################################
# Testing passing parameters to the VM's PS script
##################################################
# $ResourceGroup = "lab1hprg"
# $location = "eastus"
# $RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# # (Get-Command ./AADextention.ps1).Parameters
# $RunningVMs | ForEach-Object -Parallel {
#     Invoke-AzVMRunCommand `
#         -ResourceGroupName $_.ResourceGroupName `
#         -VMName $_.Name `
#         -CommandId 'RunPowerShellScript' `
#         -Parameter @{ResourceGroup = $using:ResourceGroup;location = $using:location} `
#         -ScriptPath '.\param_invoke.ps1'
# }

################################
#     Installing Fslogix       #
################################
$VMRG = "imageBuilderRG"
$ProfilePath = "\\imagesaaad.file.core.windows.net\avdprofiles\profiles"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{ProfilePath = $using:ProfilePath} `
        -ScriptPath './fslogix_install.ps1'
}

#######################################
# Adjusting Fslogix RegKey for AAD SA #
######################################
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$ProfilePath = "\\imagesaaad.file.core.windows.net\avdprofiles\profiles"
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{ProfilePath = $using:ProfilePath} `
        -ScriptPath './fslogix_regkey_AADSA.ps1'
}

################################
#    Adding AVD agents to VMs  #
################################
$VMRG = "imageBuilderRG"
$HPRG = "AADJoinedAVD"
$HPName = "AADJoined"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RegistrationToken = (New-AzWvdRegistrationInfo -ResourceGroupName $HPRG -HostPoolName $HPName -ExpirationTime $((get-date).ToUniversalTime().AddHours(3).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))).Token
# $RegistrationToken = Get-AzWvdRegistrationInfo -ResourceGroupName $HPRG -HostPoolName $HPName
#$RunFilePath = '.\hostpool_vms.ps1'
#((Get-Content -path $RunFilePath -Raw) -replace '<__param1__>', $RegistrationToken.Token) | Set-Content -Path $RunFilePath
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{HPRegToken = $using:RegistrationToken} `
        -ScriptPath '.\hostpool_vms.ps1'
}


