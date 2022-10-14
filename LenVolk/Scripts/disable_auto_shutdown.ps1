$resourceGroup = "azure-dev"



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

