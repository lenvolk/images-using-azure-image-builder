

$PathToCsv = "C:\Temp\MMA_Lin_VMs.csv"
$computers = (Import-Csv -Path $PathToCsv).vmname

# For Azure VMs
foreach ($vmName in $computers) { 
    $vmAzure = Get-AzVM -Name $vmName
    if ($vmAzure) {
        Write-Output "Removing MMA agent from $vmName"
        Remove-AzVMExtension -ResourceGroupName $vmAzure.ResourceGroupName -Name OmsAgentForLinux -VMName $vmAzure.Name -Force
        #for linux
        #Remove-AzVMExtension -ResourceGroupName $vmAzure.ResourceGroupName -Name OmsAgentForLinux -VMName $vmAzure.Name -Force
    } 
    else {
        Write-Output "$vmName VM not found"
    }
}


