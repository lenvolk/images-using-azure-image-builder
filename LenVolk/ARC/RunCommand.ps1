
# Ref https://github.com/johnthebrit/RandomStuff/blob/master/AzureVarious/ArcMachine.ps1
# https://learn.microsoft.com/en-us/azure/azure-arc/servers/run-command
# https://learn.microsoft.com/en-us/azure/virtual-machines/windows/run-command-managed


Install-Module -Name Az.ConnectedMachine -Scope allusers -Force

Get-AzConnectedMachine

Get-AzConnectedMachine -ResourceGroupName RG-Arc -Name winsrv2022

get-help New-AzConnectedMachineRunCommand -Examples

New-AzConnectedMachineRunCommand -ResourceGroupName RG-Arc -SourceScript 'Write-Host "Hostname: $env:COMPUTERNAME, Username: $env:USERNAME"' `
    -RunCommandName "runGetInfo10" -MachineName winsrv2022 -Location WestUS2

get-AzConnectedMachineRunCommand -MachineName winsrv2022 -ResourceGroupName RG-Arc -RunCommandName "runGetInfo10"

New-AzConnectedMachineRunCommand -ResourceGroupName RG-Arc -SourceScript 'Write-Host "Hostname: $env:COMPUTERNAME, Username: $env:USERNAME"' `
    -RunCommandName "runGetInfo11" -MachineName winsrv2022 -Location WestUS2 `
    -AsyncExecution

#Can use -ScriptURI etc


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

# $ArcMachines = Search-AzGraph -Query "Resources | where type =~ 'microsoft.hybridcompute/machines' | extend agentversion = properties.agentVersion | project name, agentversion, location, resourceGroup, subscriptionId"

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