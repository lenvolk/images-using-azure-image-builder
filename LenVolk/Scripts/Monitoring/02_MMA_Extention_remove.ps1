

$PathToCsv = "C:\Temp\MMA_VMs.csv"
$computers = (Import-Csv -Path $PathToCsv).vmname

# For Azure VMs
foreach ($vmName in $computers) { 
    $vmAzure = Get-AzVM -Name $vmName
    if ($vmAzure) {
        Write-Output "Removing MMA agent from $vmAzure"
        #Remove-AzVMExtension -ResourceGroupName $vmAzure.ResourceGroupName -Name MicrosoftMonitoringAgent -VMName $vmAzure.Name -Force
    } 
    else {
        Write-Output "$vmName VM not found"
    }
}