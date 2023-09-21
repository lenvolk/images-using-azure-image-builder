# REF 
# Migration workbook  https://learn.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-migration-tools
# report on LAW agent https://argonsys.com/microsoft-cloud/library/how-to-find-your-azure-log-analytics-agent-deployments-in-preparation-for-the-azure-monitor-agent/


$subscription = "DemoSub"

Connect-AzAccount -Subscription $subscription 
Set-AzContext -Subscription $subscription


# Create Report Array
$report = @()
$reportName = "MMA_Lin_VMs.csv"

$VMs = Get-AzVM 

$LinuxVMs = $VMs | Where-Object  {$_.StorageProfile.OsDisk.OsType -eq "Linux" }
foreach ($VM in $LinuxVMs) {

    $ReportDetails = "" | Select VmName, ResourceGroupName

    $extension = Get-AzVMExtension -ResourceGroupName $Vm.ResourceGroupName -VMName $VM.Name

    if ($extension.Name -contains "OmsAgentForLinux") {
        #Write-Host "Microsoft Monitoring Agent is Installed on" $VM.Name "in the RG:" $VM.ResourceGroupName
        $ReportDetails.VMName = $vm.Name 
        $ReportDetails.ResourceGroupName = $vm.ResourceGroupName 
        $report+=$ReportDetails 
        }
}

$report | ft -AutoSize VmName, ResourceGroupName
 
#Change the path based on your convenience
$report | Export-CSV  "c:\temp\$reportName" –NoTypeInformation

