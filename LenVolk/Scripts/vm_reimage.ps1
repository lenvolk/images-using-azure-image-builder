param (
    [string]$VMresourceGroup,
    [string]$ImageId
)

# $VMresourceGroup ="IMAGEBUILDERRG"
# $VMname = "ChocoWin11m365"
# $current_vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMname
# $current_vm.StorageProfile.ImageReference.Id

function Reimage-Vms {
    param (
        $vms
    )
    $vms | ForEach-Object -Parallel {
        try {
            $current_vm = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name
            $current_vm.StorageProfile.ImageReference.Id = $ImageId
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

    write-host "AVD VM list:"
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