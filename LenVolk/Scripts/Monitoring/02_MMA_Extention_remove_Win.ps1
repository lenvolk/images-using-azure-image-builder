

$PathToCsv = "C:\Temp\MMA_VMs.csv"
$computers = (Import-Csv -Path $PathToCsv).vmname

# For Azure VMs
foreach ($vmName in $computers) { 
    $vmAzure = Get-AzVM -Name $vmName
    if ($vmAzure) {
        Write-Output "Removing MMA agent from $vmName"
        Remove-AzVMExtension -ResourceGroupName $vmAzure.ResourceGroupName -Name MicrosoftMonitoringAgent -VMName $vmAzure.Name -Force
        #for linux
        #Remove-AzVMExtension -ResourceGroupName $vmAzure.ResourceGroupName -Name OmsAgentForLinux -VMName $vmAzure.Name -Force
    } 
    else {
        Write-Output "$vmName VM not found"
    }
}


#########################
#     Azure Arc MMA     #
#########################
# # $subid = "ca5dfa45-eb4e-4612-9ebd-06f6fc3bc996"
# # Set-AzContext -Subscription $subid
# $PathToCsv = "C:\Temp\MMA_Arc.csv"
# $computers = Import-Csv -Path $PathToCsv

# # For Azure VMs
# foreach ($vmName in $computers) { 

#         Remove-AzConnectedMachineExtension -MachineName $vmName.VmName -ResourceGroupName $vmName.ResourceGroupName -Name OmsAgentforLinux -NoWait
#         Remove-AzConnectedMachineExtension -MachineName $vmName.VmName -ResourceGroupName $vmName.ResourceGroupName -Name AzureMonitorLinuxAgent -NoWait
#         Write-Output "Machine Name: $($vmName.VmName) has MMA removed"
# }