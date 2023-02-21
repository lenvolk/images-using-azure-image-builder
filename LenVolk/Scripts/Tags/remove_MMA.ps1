#     Login to Azure first:
#             $subscription = "ca5dfa45-eb4e-4612-9ebd-06f6fc3bc996"
#             az logout
#             Login-AzAccount -Subscription $subscription 
#             Select-AzSubscription -Subscription $subscription 


$PathToCsv = "C:\Temp\BackUP\Temp\images-using-azure-image-builder\LenVolk\Scripts\Tags\computers.csv"
$computers = Get-Content -Path $PathToCsv

$tags = @{'PCI' = 'Yes'; 'Department'='Accounting'; 'Environment'='Dev'} 

# For Azure VMs
foreach ($vmName in $computers) { 
    # Write-Host ".... Assigning $tags to VM Name $computer "
    # Update-AzTag -Tag $tags -ResourceId "/subscriptions/<subID>/resourceGroups/<RGName>/providers/Microsoft.Compute/virtualMachines/$vmName" -Operation Merge -Verbose
    $vmAzure = Get-AzVM -Name $vmName
    if ($vmAzure) {
        Write-Output "Removing MMA agent"
        Remove-AzVMExtension -ResourceGroupName $vmAzure.ResourceGroupName -Name MicrosoftMonitoringAgent -VMName $vmAzure.Name
        


    } else {
        Write-Output "$vmName VM not found"
    }
}
