

$PathToCsv = "C:\Temp\MMA_VMs.csv"
$computers = Import-Csv -Path $PathToCsv | select VmName

$vms = ($computers.psobject.Properties | Select Value)

# Get-AzVM -Name $vms


# For Azure VMs
foreach ($vmName in $vms) { 
    $vmAzure = Get-AzVM -Name $vmName
    if ($vmAzure) {
        Write-Output "Removing MMA agent"
        Remove-AzVMExtension -ResourceGroupName $vmAzure.ResourceGroupName -Name MicrosoftMonitoringAgent -VMName $vmAzure.Name -Force
    } 
    else {
        Write-Output "$vmName VM not found"
    }
}