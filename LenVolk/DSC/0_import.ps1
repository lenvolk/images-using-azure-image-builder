

#######################################
#      IMPORT THE CONFIGURATION       #
#######################################
$grp="automation"
Import-AzAutomationDscConfiguration -Published -ResourceGroupName $grp -SourcePath ./file.ps1 -Force -AutomationAccountName Automation

#######################################
#            Enable DSC               #
#######################################

$VMRG = "WorkStation"
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 

$AutomationAccount = "automation"
$AutomationRG = "automation"

   $RunningVMs | ForEach-Object -Parallel {
        Register-AzAutomationDscNode `
           -AzureVMName $_.Name `
           -AzureVMLocation $_.Location `
           -NodeConfigurationName "file.localhost" `
           -ConfigurationMode "ApplyAndAutocorrect" `
           -AutomationAccountName $using:AutomationAccount `
           -ResourceGroupName $using:AutomationRG -Verbose
   }


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
