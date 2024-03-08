
# Ref https://github.com/johnthebrit/RandomStuff/blob/master/AzureVarious/ArcMachine.ps1
# The Connected Machine agent version must be 1.33 or higher to use the Az.ConnectedMachine module.
# https://learn.microsoft.com/en-us/azure/azure-arc/servers/run-command
# https://learn.microsoft.com/en-us/azure/virtual-machines/windows/run-command-managed


Install-Module -Name Az.ConnectedMachine -Scope CurrentUser -AllowClobber -Force
# Import-Module Az.ConnectedMachine -Force
# Get-Command -Module Az.ConnectedMachine

Get-AzConnectedMachine | Format-Table Name, AgentVersion, ResourceGroupName, Location -AutoSize

Get-AzConnectedMachine -ResourceGroupName ARC-V1 -Name ArcBox-Win2K22

# get-help New-AzConnectedMachineRunCommand -Examples

New-AzConnectedMachineRunCommand -ResourceGroupName ARC-V1 -SourceScript 'Write-Host "Hostname: $env:COMPUTERNAME, Username: $env:USERNAME"' `
    -RunCommandName "runGetInfo10" -MachineName ArcBox-Win2K22 -Location EastUS

get-AzConnectedMachineRunCommand -MachineName ArcBox-Win2K22 -ResourceGroupName ARC-V1 -RunCommandName "runGetInfo10"

New-AzConnectedMachineRunCommand -ResourceGroupName ARC-V1 -SourceScript 'Write-Host "Hostname: $env:COMPUTERNAME, Username: $env:USERNAME"' `
    -RunCommandName "runGetInfo11" -MachineName ArcBox-Win2K22 -Location EastUS `
    -AsyncExecution

# List all runCommands
$RCom = Get-AzConnectedMachineRunCommand -ResourceGroupName ARC-V1 -MachineName ArcBox-Win2K22

# Delete Need to authenticate via az cli
az login --only-show-errors -o table --query Dummy
$subscription = "On-Prem"
az account set -s $subscription
# az logout
az connectedmachine run-command delete --name runGetInfo10 --machine-name ArcBox-Win2K22 --resource-group ARC-V1
az connectedmachine run-command delete --name runGetInfo11 --machine-name ArcBox-Win2K22 --resource-group ARC-V1

# $RCom | ForEach-Object -Parallel {
#         az connectedmachine run-command Delete `
#          --name $_.Name `
#          --machine-name "ArcBox-Win2K22" `
#          --resource-group $_.ResourceGroupName
# }

# Create or update Run Command on a machine resource using SourceScriptUri (storage blob SAS URL)
# https://learn.microsoft.com/en-us/azure/azure-arc/servers/run-command#create-or-update-run-command-on-a-machine-resource-using-sourcescripturi-storage-blob-sas-url
### 
$LocalPath            = "c:\temparc"
if((Test-Path $LocalPath) -eq $false) {
    New-Item -Path $LocalPath -ItemType Directory
}

Set-Location -Path $LocalPath

$DSCOnBoard              = '<ScriptBlobURLSAS>'
$MOFName                 = 'ArcBox-Win2K22.meta.mof'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $DSCOnBoard -OutFile "$MOFName"

Set-DscLocalConfigurationManager -Path $LocalPath -Force
###
New-AzConnectedMachineRunCommand -ResourceGroupName ARC-V1 -MachineName ArcBox-Win2K19 -RunCommandName runGetInfo12 -Location EastUS -SourceScriptUri "https://arcboxeg2bfl3thdl36.blob.core.windows.net/scripts/arcruntst.ps1?xxxxxxxx"

New-AzConnectedMachineRunCommand -ResourceGroupName ARC-V1 -MachineName ArcBox-Win2K22 -RunCommandName runGetInfo12 -Location EastUS -SourceScriptUri "https://arcboxeg2bfl3thdl36.blob.core.windows.net/scripts/arcruntst.ps1?xxxxxxxx"

## Graph  https://github.com/johnthebrit/RandomStuff/blob/master/AzureVMMS/run.ps1
# $GraphSearchQuery = "Resources
# | where type =~ 'Microsoft.Compute/virtualMachineScaleSets'
# | join kind=inner (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
# | project VMMSName = name, RGName = resourceGroup, SubName, SubID = subscriptionId, ResID = id"
# $VMMSResources = Search-AzGraph -Query $GraphSearchQuery


# #########################################
# #     Azure Arc MMA  with Azure Graph   #
# #########################################
# # Ref https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-arc/servers/manage-vm-extensions-powershell.md
# # $subid = "ca5dfa45-eb4e-4612-9ebd-06f6fc3bc996"
# # Set-AzContext -Subscription $subid
# # Install-Module -Name Az.ConnectedMachine -Verbose -Force
# # Install the Resource Graph module from PowerShell Gallery
# # Install-Module -Name Az.ResourceGraph -Verbose -Force

# # Create Report Array
# $report = @()
# $reportName = "MMA_Arc.csv"

# $ArcMachines = Search-AzGraph -Query "Resources | where type =~ 'microsoft.hybridcompute/machines' | extend agentversion = properties.agentVersion | project name, properties.osSku, agentversion, location, resourceGroup, subscriptionId"

# foreach ($ArcName in $ArcMachines) { 
     
#     $ReportDetails = "" | Select VmName, ResourceGroupName
#     $extension = Get-AzConnectedMachineExtension -ResourceGroupName $ArcName.resourceGroup -MachineName $ArcName.Name

#     if (($extension.Name -like "AzureMonitor*") -or ($extension.Name -like "OMSAgent*")) {
#         Write-Output "$($ArcName.Name) has MMA"
#         $ReportDetails.VMName = $ArcName.Name 
#         $ReportDetails.ResourceGroupName = $ArcName.resourceGroup
#         $report+=$ReportDetails 
#     } 
# }

# $report | ft -AutoSize VmName, ResourceGroupName
 
# #Change the path based on your convenience
# $report | Export-CSV  "c:\temp\$reportName" –NoTypeInformation