



$arcServers = Get-AzConnectedMachine -ResourceGroupName "ARC"
# Filter servers with agent version below 1.48.02881.1941 and status "connected"
$filteredServers = $arcServers | Where-Object {
    $_.Status -eq "connected"
}


$filteredServers | ForEach-Object -Parallel {
    Remove-AzConnectedMachineExtension `
        -ResourceGroupName $_.ResourceGroupName `
        -MachineName $_.Name `
        -Name "MDE.Windows" `
        -NoWait
}