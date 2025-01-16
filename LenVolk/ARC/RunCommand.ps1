
# Ref https://github.com/johnthebrit/RandomStuff/blob/master/AzureVarious/ArcMachine.ps1
# The Connected Machine agent version must be 1.33 or higher to use the Az.ConnectedMachine module.
# https://learn.microsoft.com/en-us/azure/azure-arc/servers/run-command
# https://learn.microsoft.com/en-us/azure/virtual-machines/windows/run-command-managed

######################################################################################
### download source for Azure Arc-enabled servers extensions
#
# The URL https://oaasguestconfigeuss1.blob.core.windows.net [oaasguestconfigeuss1.blob.core.windows.net] is the default download source for all the extensions, and it is required for the normal operation. 
# The extension service (gc_extension_service) tries to communicate with this URL via the Arc agent through the configured proxy.
#
# When using Private Link, this URL is not used. Instead, the extension service tries to communicate with a private endpoint that resolves the *.blob.core.windows.net domain. 
# This is where the bug occurs, as the URI is malformed and the signature file cannot be validated.
######################################################################################
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
# $subscription = "ARC-Demo"
# az account set -s $subscription
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

New-AzConnectedMachineRunCommand -ResourceGroupName ARC-V1 -MachineName ArcBox-Win2K22 -RunCommandName runGetInfo12 -Location EastUS -SourceScriptUri "https://arcboxeg2bfl3thdl36.blob.core.windows.net/scripts/DelConflictFiles.ps1?xxxxxxx"

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

#### Update ARC Agent

# Login to Azure
Connect-AzAccount

# Set the subscription context
Set-AzContext -SubscriptionName "ARC-Demo"
# Get all Azure Arc servers in the specified resource group
$arcServers = Get-AzConnectedMachine -ResourceGroupName "ARC"
# Filter servers with agent version below 1.48.02881.1941 and status "connected"
$filteredServers = $arcServers | Where-Object {
    [version]$_.AgentVersion -lt [version]"1.48.02881.1941" -and $_.Status -eq "connected"
}

# Output the filtered servers
#$filteredServers | Select-Object Name, AgentVersion, Status

# New-AzConnectedMachineRunCommand -ResourceGroupName ARC -MachineName PUB2 -RunCommandName arcagupd01 -Location CentralUS  -SourceScriptUri "https://sharexvolkbike.blob.core.windows.net/scripts/arcagent.ps1?sp=r&st=2025-01-16T19:28:19Z&se=2025-01-30T03:28:19Z&spr=https&sv=2022-11-02&sr=b&sig=E%2F0Y8pH%2FbirvP1Te0XJtbNGB%2FH38vcsZ4O%2FJZ2bDdl8%3D"

# Loop through the filtered servers and execute the run command
foreach ($server in $filteredServers) {
    New-AzConnectedMachineRunCommand -ResourceGroupName $server.ResourceGroupName `
    -MachineName $server.Name `
    -RunCommandName "arcagupd03" `
    -Location $server.Location `
    -SourceScriptUri "https://sharexvolkbike.blob.core.windows.net/scripts/arcagent.ps1?sp=r&st=2025-01-16T19:28:19Z&se=2025-01-30T03:28:19Z&spr=https&sv=2022-11-02&sr=b&sig=E%2F0Y8pH%2FbirvP1Te0XJtbNGB%2FH38vcsZ4O%2FJZ2bDdl8%3D" `
    -AsJob
}

# $filteredServers | ForEach-Object -Parallel {
#     New-AzConnectedMachineRunCommand `
#         -ResourceGroupName $_.ResourceGroupName `
#         -MachineName $_.Name `
#         -RunCommandName "arcagupd04" `
#         -Location $_.Location `
#         -SourceScriptUri "https://sharexvolkbike.blob.core.windows.net/scripts/arcagent.ps1?sp=r&st=2025-01-16T19:28:19Z&se=2025-01-30T03:28:19Z&spr=https&sv=2022-11-02&sr=b&sig=E%2F0Y8pH%2FbirvP1Te0XJtbNGB%2FH38vcsZ4O%2FJZ2bDdl8%3D" `
#         -AsJob
# }


# Get-AzConnectedMachineRunCommand -ResourceGroupName ARC -MachineName PUB2
# get-AzConnectedMachineRunCommand -ResourceGroupName ARC -MachineName PUB2 -RunCommandName arcagupd2
# az connectedmachine run-command delete --name arcagupd2 --machine-name PUB2 --resource-group ARC

# Define the URL and file path   https://img.volk.bike/arcagent.ps1
# $msiUrl = "https://aka.ms/AzureConnectedMachineAgent"
# $msiPath = "C:\Support\Logs\AzureConnectedMachineAgent.msi"

# # Create the folder if it doesn't exist
# if (-not (Test-Path -Path "C:\Support\Logs")) {
#     New-Item -ItemType Directory -Path "C:\Support\Logs"
# }

# # Download the MSI file
# Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

# # Execute the MSI file
# Start-Process msiexec.exe -ArgumentList "/i $msiPath /qn /l*v `"C:\Support\Logs\azcmagentupgradesetup.log`"" -Wait
