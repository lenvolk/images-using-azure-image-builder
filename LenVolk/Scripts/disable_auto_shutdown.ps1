$resourceGroup = "Lab1HPRG"
$hostPool = "Lab1HP"


$RunningVMs = (get-azvm -ResourceGroupName $resourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 

$RunningVMs | ForEach-Object -Parallel {
    try {
        az vm auto-shutdown -g $_.ResourceGroupName -n $_.Name --off 
        }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ("Error disabling auto shutdown: " + $ErrorMessage)
        Break
    }
}

####### By the HostPool

$PoolVMs = Get-AzWvdSessionHost -ResourceGroupName $resourceGroup -HostPoolName $hostPool

$PoolVMs | ForEach-Object -Parallel {
    try {
    az vm auto-shutdown -g "Lab1HPRG" -n ((($_.Name -split '/')[1]) -split '.lvolk.com') --off 
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ("Error disabling auto shutdown: " + $ErrorMessage)
        Break
    }
}

# Get active sessions on all the Session Host
# foreach ($PoolVM in $PoolVMs) {
#     $vmname = (($PoolVM.Name -split '/')[1]) -split '.lvolk.com'
#     #$vmname = ($vmname.Substring($vmname.IndexOf("/")+1)).Trim(".domain")
#     Write-Output $vmname
#     az vm auto-shutdown -g "Lab1HPRG" -n $vmname --off 
# }


