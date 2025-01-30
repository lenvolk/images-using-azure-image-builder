$StoppedVMs = (get-azvm -ResourceGroupName "imageBuilderRG" -Status) | Where-Object { $_.PowerState -eq "VM stopped" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 

$StoppedVMs | ForEach-Object -Parallel {
    try {
        $displayStatus = ""
        $count = 0
        Stop-AzVM -ErrorAction Stop -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Force | Out-Null
        while ($displayStatus -notlike "VM deallocated") {
            Write-Host "Waiting for the VM display status to change to VM deallocated"
            $displayStatus = (get-azvm -ErrorAction Stop -Name $_.Name -ResourceGroupName $_.ResourceGroupName -Status).Statuses[1].DisplayStatus
            write-output "starting 15 second sleep"
            start-sleep -Seconds 15
            $count += 1
            if ($count -gt 11) {
                Write-Error "Three minute wait for VM to be deallocated ended, canceling script.  Verify no updates are required on the source"
                Exit 
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ("Error deallocating: " + $ErrorMessage)
        Break
    }
    ### Starting VMs
    try {
        $displayStatus = ""
        $count = 0
        Start-AzVM -ErrorAction Stop -ResourceGroupName $_.ResourceGroupName -Name $_.Name | Out-Null
        while ($displayStatus -notlike "VM running") {
            Write-Host "Waiting for the VM display status to change to VM running"
            $displayStatus = (get-azvm -ErrorAction Stop -Name $_.Name -ResourceGroupName $_.ResourceGroupName -Status).Statuses[1].DisplayStatus
            write-output "starting 15 second sleep"
            start-sleep -Seconds 15
            $count += 1
            if ($count -gt 11) {
                Write-Error "Three minute wait for VM to be running ended, canceling script.  Verify no updates are required on the source"
                Exit 
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ("Error deallocating: " + $ErrorMessage)
        Break
    }
}


### Testing
# Connect to VM $VMIP= "20.7.0.224"
# $VM_User = "aibadmin"
# $WinVM_Password = "P@ssw0rdP@ssw0rd"
# cmdkey /generic:$VMIP /user:$VM_User /pass:$WinVM_Password
# mstsc /v:$VMIP /w:1440 /h:900


# $StoppedVMs = (get-azvm -ResourceGroupName "imageBuilderRG" -Status) | Where-Object { $_.PowerState -eq "VM stopped" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 

# $StoppedVMs | ForEach-Object -Parallel {
#     try {
#         Stop-AzVM -ErrorAction Stop -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Force | Out-Null
#         }
#     catch {
#         $ErrorMessage = $_.Exception.message
#         Write-Error ("Error deallocating: " + $ErrorMessage)
#         Break
#     }
# }

# start-sleep -Seconds 180

# $DeallocatedVMs = (get-azvm -ResourceGroupName "imageBuilderRG" -Status) | Where-Object { $_.PowerState -eq "VM deallocated" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 

# $DeallocatedVMs | ForEach-Object -Parallel {
#     try {
#         Start-AzVM -ErrorAction Stop -ResourceGroupName $_.ResourceGroupName -Name $_.Name | Out-Null
#         }
#     catch {
#         $ErrorMessage = $_.Exception.message
#         Write-Error ("Error Starting: " + $ErrorMessage)
#         Break
#     }
# }