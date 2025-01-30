param (
    [string]$VMresourceGroup,
    [string]$action
)
 
write-host "################################"
write-host "Action set to: $VMresourceGroup"
write-host "Action set to: $action"
write-host "PS Version: $PSVersionTable"
function Stop-Vms {
    param (
        $vms
    )
    $vms | ForEach-Object -Parallel {
        try {
            # Start the VM
            stop-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -ErrorAction Stop -Force -NoWait
        }
        catch {
            $ErrorMessage = $_.Exception.message
            Write-Error ("Error stopping the VM: " + $ErrorMessage)
            Break
        }
    }
 
}  
 
function Restart-Vms {
    param (
        $vms
    )
    $vms | ForEach-Object -Parallel {
        try {
            # Start the VM
            Restart-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -ErrorAction Stop -NoWait
        }
        catch {
            $ErrorMessage = $_.Exception.message
            Write-Error ("Error restarting the VM: " + $ErrorMessage)
            Break
        }
    }
 
} 

function Start-Vms {
    param (
        $vmsdown
    )
    $vmsdown | ForEach-Object -Parallel {
        try {
            # Start the VM
            start-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -ErrorAction Stop -NoWait
        }
        catch {
            $ErrorMessage = $_.Exception.message
            Write-Error ("Error starting the VM: " + $ErrorMessage)
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
 
# call the restart or stop function
If ($action -eq "restart") {
    write-host "Starting the following servers:"
    write-host $vms.Name
    Restart-Vms $vms
}
elseif ($action -eq "stop") {
    write-host "Stopping the following servers:"
    write-host $vms.Name
    stop-vms $vms
}
elseif ($action -eq "start") {
    write-host "Starting the following servers:"
    write-host $vmsdown.Name
    start-vms $vmsdown
}
else {
    write-host "no servers were started or stopped"
}