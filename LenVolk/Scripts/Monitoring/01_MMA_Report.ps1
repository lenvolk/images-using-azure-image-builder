# REF 
# Migration workbook  https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-migration-tools
# report on LAW agent https://argonsys.com/microsoft-cloud/library/how-to-find-your-azure-log-analytics-agent-deployments-in-preparation-for-the-azure-monitor-agent/

# Create Report Array
$report = @()
$reportName = "MMA_VMs.csv"

$VMs = Get-AzVM 
# $WindowsServers = $VMs | Where-Object { $PSItem.StorageProfile.ImageReference.Offer -eq "WindowsServer" }
$WindowsVMs = $VMs | Where-Object  {$_.StorageProfile.OsDisk.OsType -eq "Windows" }

foreach ($VM in $WindowsVMs) {

    $ReportDetails = "" | Select VmName, ResourceGroupName

    $extension = Get-AzVMExtension -ResourceGroupName $Vm.ResourceGroupName -VMName $VM.Name

    if ($extension.Name -contains "MicrosoftMonitoringAgent") {
        #Write-Host "Microsoft Monitoring Agent is Installed on" $VM.Name "in the RG:" $VM.ResourceGroupName
        $ReportDetails.VMName = $vm.Name 
        $ReportDetails.ResourceGroupName = $vm.ResourceGroupName 
        $report+=$ReportDetails 
        }
}

$report | ft -AutoSize VmName, ResourceGroupName
 
#Change the path based on your convenience
$report | Export-CSV  "c:\temp\$reportName" –NoTypeInformation

#########################
#     Azure Arc MMA     #
#########################
# Ref https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/azure-arc/servers/manage-vm-extensions-powershell.md
# $subid = "ca5dfa45-eb4e-4612-9ebd-06f6fc3bc996"
# Set-AzContext -Subscription $subid
# Install-Module -Name Az.ConnectedMachine -Verbose -Force
# Install the Resource Graph module from PowerShell Gallery
# Install-Module -Name Az.ResourceGraph -Verbose -Force

# Create Report Array
$report = @()
$reportName = "MMA_Arc.csv"

$ArcMachines = Search-AzGraph -Query "Resources | where type =~ 'microsoft.hybridcompute/machines' | extend agentversion = properties.agentVersion | project name, agentversion, location, resourceGroup, subscriptionId"

foreach ($ArcName in $ArcMachines) { 
     
    $ReportDetails = "" | Select VmName, ResourceGroupName
    $extension = Get-AzConnectedMachineExtension -ResourceGroupName $ArcName.resourceGroup -MachineName $ArcName.Name

    if (($extension.Name -like "AzureMonitor*") -or ($extension.Name -like "OMSAgent*")) {
        Write-Output ""$ArcName.Name" has MMA"
        $ReportDetails.VMName = $ArcName.Name 
        $ReportDetails.ResourceGroupName = $ArcName.resourceGroup
        $report+=$ReportDetails 
    } 
}

$report | ft -AutoSize VmName, ResourceGroupName
 
#Change the path based on your convenience
$report | Export-CSV  "c:\temp\$reportName" –NoTypeInformation