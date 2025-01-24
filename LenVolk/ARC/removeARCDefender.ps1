



$arcServers = Get-AzConnectedMachine -ResourceGroupName "ARC"
# Filter servers with agent version below 1.48.02881.1941 and status "connected"
$filteredServers = $arcServers | Where-Object {
    $_.Status -eq "connected"
}



# foreach ($server in $filteredServers) {
#     $extensions = Get-AzConnectedMachineExtension -ResourceGroupName "ARC" -MachineName $server.Name
#     $mdeExtension = $extensions | Where-Object { $_.Name -eq "MDE.Windows" }

#     if ($mdeExtension) {
#         Remove-AzConnectedMachineExtension -ResourceGroupName "ARC" -MachineName $server.Name -Name "MDE.Windows"
#         Write-Output "Removed MDE.Windows extension from $($server.Name)"
#     } else {
#         Write-Output "MDE.Windows extension not found on $($server.Name)"
#     }
# }




$filteredServers | ForEach-Object -Parallel {
    Remove-AzConnectedMachineExtension `
        -ResourceGroupName $_.ResourceGroupName `
        -MachineName $_.Name `
        -Name "MDE.Windows" `
        -NoWait
}