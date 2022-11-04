$StoppedVMs = (get-azvm -ResourceGroupName "imageBuilderRG" -Status) | Where-Object { $_.PowerState -eq "VM stopped" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 

$StoppedVMs | ForEach-Object -Parallel {
    try {
        Stop-AzVM -ErrorAction Stop -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Force | Out-Null
        }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ("Error deallocating: " + $ErrorMessage)
        Break
    }
}

start-sleep -Seconds 180

$DeallocatedVMs = (get-azvm -ResourceGroupName "imageBuilderRG" -Status) | Where-Object { $_.PowerState -eq "VM deallocated" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 

$DeallocatedVMs | ForEach-Object -Parallel {
    try {
        Start-AzVM -ErrorAction Stop -ResourceGroupName $_.ResourceGroupName -Name $_.Name | Out-Null
        }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ("Error Starting: " + $ErrorMessage)
        Break
    }
}

### Testing
# Connect to VM $VMIP= "20.7.0.224"
# $VM_User = "aibadmin"
# $WinVM_Password = "P@ssw0rdP@ssw0rd"
# cmdkey /generic:$VMIP /user:$VM_User /pass:$WinVM_Password
# mstsc /v:$VMIP /w:1440 /h:900