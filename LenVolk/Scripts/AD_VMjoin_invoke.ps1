
# REF: https://learn.microsoft.com/en-us/powershell/module/az.compute/set-azvmaddomainextension?view=azps-9.2.0&viewFallbackFrom=azps-4.4.0
# Logs: C:\WindowsAzure\Logs\Plugins
#       C:\Packages\Plugins
# From PS: net use \\dc1.lvolk.com\ipc$ /u:lvolk\lv <mypassword>


$VMRG = "imageBuilderRG"
$DomainName = "lvolk.com"
$OUPath = "OU=PoolHostPool,OU=AVD,DC=lvolk,DC=com"
$credential = Get-Credential lv@lvolk.com

# $RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows"} 

# # $RunningVMs | ForEach-Object -Parallel {
# #     Invoke-AzVMRunCommand `
# #         -ResourceGroupName $_.ResourceGroupName `
# #         -VMName $_.Name `
# #         -CommandId 'RunPowerShellScript' `
# #         -Parameter @{DomainName = $using:DomainName;
# #                      OUPath = $using:OUPath;
# #                      credential = $using:credential} `
# #         -ScriptPath './AD_VMjoin_script.ps1'
# # }

# $RunningVMs | ForEach-Object -Parallel {
#     Invoke-AzVMRunCommand `
#     -ResourceGroupName $_.ResourceGroupName `
#     -VMName $_.Name `
#     -CommandId 'RunPowerShellScript' `
#     -ScriptString { Add-Computer -DomainName $DomainName -OUPath $OUPath -Credential $credential -Force }
# }

###################################
# Using Set-AzVMADDomainExtension 
###################################

# $extensionName = 'lvolkdomainjoin'
# $DomainName = 'lvolk.com'
# $OUPath = 'OU=PoolHostPool,OU=AVD,DC=lvolk,DC=com'
# $VMName = 'avd-win11-01'
# $credential = Get-Credential 'lvolk\lv'
# $ResourceGroupName = 'imageBuilderRG'
 
# Set-AzVMADDomainExtension -Name $extensionName -DomainName $DomainName -OUPath $OUPath  -VMName $VMName -Credential $credential -ResourceGroupName $ResourceGroupName -JoinOption 0x00000001 -Restart -Verbose


$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows"} | Select Name
