
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