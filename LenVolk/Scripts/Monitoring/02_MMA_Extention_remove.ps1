

$PathToCsv = "C:\Temp\MMA_VMs.csv"
$computers = Import-Csv -Path $PathToCsv | select VmName

$vms = ($computers.psobject.Properties | Select Value)

Get-AzVM -Name $vms


# For Azure VMs
# foreach ($vmName in $vms) { 
#     # Write-Host ".... Assigning $tags to VM Name $computer "
#     # Update-AzTag -Tag $tags -ResourceId "/subscriptions/<subID>/resourceGroups/<RGName>/providers/Microsoft.Compute/virtualMachines/$vmName" -Operation Merge -Verbose
#     $vmAzure = Get-AzVM -Name $vmName
#     if ($vmAzure) {
#         Write-Output "$vmName VM updating Tags"
#         Update-AzTag -ResourceId $vmAzure.Id -Operation Merge -Tag $tags

#         if ($vmAzure.StorageProfile.OsDisk.ManagedDisk.Id) {
#             Write-Output "> $vmName Disk $($vmAzure.StorageProfile.OsDisk.Name) updating Tags"
#             Update-AzTag -ResourceId $vmAzure.StorageProfile.OsDisk.ManagedDisk.Id -Operation Merge -Tag $tags
#         }

#         foreach ($nic in $vmAzure.NetworkProfile.NetworkInterfaces) {
#             Write-Output "> $vmName NIC updating Tags"
#             Update-AzTag -ResourceId $nic.Id -Operation Merge -Tag $tags
#         }
#         foreach ($disk in $vmAzure.StorageProfile.DataDisks) {
#             Write-Output "> $vmName Disk $($disk.Name) updating Tags"
#             $azResource = Get-AzResource -Name "$($disk.Name)"
#             Update-AzTag -ResourceId $azResource.Id -Operation Merge -Tag $tags
#         }

#     } else {
#         Write-Output "$vmName VM not found"
#     }
# }


# Remove-AzVMExtension -ResourceGroupName "ResourceGroup11" -Name "ContosoTest" -VMName "VirtualMachine22"


