param (
    [string]$VMresourceGroup,
    [string]$ImageId
)

function Reimage-Vms {
    param (
        $vms
    )
    $vms | ForEach-Object -Parallel {
        try {
            $current_vm = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name
            $current_vm.StorageProfile.ImageReference.Id = "/subscriptions/xxxxxxx/resourceGroups/xxxxx/providers/Microsoft.Compute/galleries/xxxxxx/images/win10ms/versions/0.3.1"
            Update-AzVm -ResourceGroupName $_.ResourceGroupName -VM $current_vm
        }
        catch {
            $ErrorMessage = $_.Exception.message
            Write-Error ("Error reimaging the VM: " + $ErrorMessage)
            Break
        }
    }
 
} 

try {
    # Restart the VM
    $vms = (get-azvm -ResourceGroupName $VMresourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" `
            -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
    $vmsdown = (get-azvm -ResourceGroupName $VMresourceGroup -Status) | Where-Object { $_.PowerState -eq "VM deallocated" `
            -and $_.StorageProfile.OsDisk.OsType -eq "Windows" }

    write-host "WVD VM list:"
    write-host $vms.name
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ("Error returning the VMs: " + $ErrorMessage)
    Break
}

write-host "Reimaging the following servers:"
write-host $vms.Name
Reimage-Vms $vms