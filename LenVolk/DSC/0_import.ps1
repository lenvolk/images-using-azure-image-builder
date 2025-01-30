
# Examples https://learn.microsoft.com/en-us/powershell/dsc/reference/resources/windows/scriptresource?view=dsc-1.1

#######################################
#      IMPORT THE CONFIGURATION       #
#######################################
# Ref: https://itnext.io/azure-automation-configuring-desired-state-configuration-4091d94e85d9

$grp="automation"
Import-AzAutomationDscConfiguration -Published -ResourceGroupName $grp -SourcePath ./file.ps1 -Force -AutomationAccountName Automation
# Compiling
Start-AzAutomationDscCompilationJob `
    -ConfigurationName 'file' `
    -ResourceGroupName 'automation' `
    -AutomationAccountName 'automation' `

# Obtain metadata for DSC configuration and ensure RollupStatus is Good
Get-AzAutomationDscNodeConfiguration `
     -ResourceGroupName $AutomationRG `
     -AutomationAccountName $AutomationAccount


#######################################
#            Enable DSC               #
#######################################
# Register the virtual machine - TST
# Register-AzAutomationDscNode `
#     -AzureVMName "Lab1SHv1-1" `
#     -AzureVMLocation "eastus" `
#     -AzureVMResourceGroup "lab1hprg" `
#     -ResourceGroupName "automation"`
#     -AutomationAccountName "automation" `
#     -NodeConfigurationName "file.localhost" `
#     -ConfigurationMode "ApplyAndAutocorrect" `
#     -RefreshFrequencyMins "30" `
#     -ActionAfterReboot "ContinueConfiguration" `
#     -RebootNodeIfNeeded $True


$VMRG = "lab1hprg"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 

$RunningVMs | ForEach-Object -Parallel {
    Register-AzAutomationDscNode `
        -AzureVMName $_.Name `
        -AzureVMLocation $_.Location `
        -AzureVMResourceGroup $_.ResourceGroupName `
        -ResourceGroupName "automation"`
        -AutomationAccountName "automation" `
        -NodeConfigurationName "file.localhost" `
        -ConfigurationMode "ApplyAndAutocorrect" `
        -RefreshFrequencyMins "30" `
        -ActionAfterReboot "ContinueConfiguration" `
        -RebootNodeIfNeeded $True
}

Get-AzAutomationDscNode -ResourceGroupName $AutomationRG -AutomationAccountName $AutomationAccount -NodeConfigurationName 'file.localhost'


# $avdDscSettings = @{
#     Name               = "Microsoft.PowerShell.DSC"
#     Type               = "DSC" 
#     Publisher          = "Microsoft.Powershell"
#     typeHandlerVersion = "2.83.2.0"
#     SettingString      = "{
#         ""modulesUrl"":'$avdModuleLocation',
#         ""ConfigurationFunction"":""Configuration.ps1\\AddSessionHost"",
#         ""Properties"": {
#             ""hostPoolName"": ""$($fileParameters.avdSettings.avdHostpool.Name)"",
#             ""registrationInfoToken"": ""$($registrationToken.token)"",
#             ""aadJoin"": true
#         }
#     }"
#     VMName             = $VMName
#     ResourceGroupName  = $resourceGroupName
#     location           = $Location
# }
# Set-AzVMExtension @avdDscSettings 
