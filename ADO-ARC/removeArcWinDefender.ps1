
param (
    [string]$ARCresourceGroup,
    [string]$ExtensionNameDefWin,
    [string]$OSType
)

# $ARCresourceGroup = 'ARC'
# $ExtensionNameDefWin = 'MDE.Windows'
# $OSType = 'Windows'

Install-Module -Name Az.ConnectedMachine -Verbose -Force
Install-Module -Name Az.ResourceGraph -Verbose -Force

$arcServers = Get-AzConnectedMachine -ResourceGroupName $ARCresourceGroup
# Filter servers with agent version below 1.48.02881.1941 and status "connected"
$filteredServers = $arcServers | Where-Object {
    $_.Status -eq "connected" -and $_.OSType -eq $OSType
}

#Write-Host "List of ARC Servers $filteredServers"

foreach ($server in $filteredServers) {
    $extensions = Get-AzConnectedMachineExtension -ResourceGroupName $ARCresourceGroup -MachineName $server.Name
    $mdeExtension = $extensions | Where-Object { $_.Name -eq "$ExtensionNameDefWin" }

    if ($mdeExtension) {
        Remove-AzConnectedMachineExtension -ResourceGroupName $ARCresourceGroup -MachineName $server.Name -Name "$ExtensionNameDefWin"
        Write-Output "Removed $ExtensionNameDefWin extension from $($server.Name)"
    } else {
        Write-Output "$ExtensionNameDefWin extension not found on $($server.Name)"
    }
}




# $filteredServers | ForEach-Object -Parallel {
#     Remove-AzConnectedMachineExtension `
#         -ResourceGroupName $_.ResourceGroupName `
#         -MachineName $_.Name `
#         -Name "$ExtensionNameDefWin" `
#         -NoWait
# }

