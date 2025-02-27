param (
    [string]$ARCresourceGroup,
    [string]$OSType
)

# $ARCresourceGroup = "ARC"
# $OSType = "Linux"

Install-Module -Name Az.ConnectedMachine -Verbose -Force
#Install-Module -Name Az.ResourceGraph -Verbose -Force


# Chrome Install
$arcServers = Get-AzConnectedMachine -ResourceGroupName $ARCresourceGroup
# Filter servers with agent version below 1.48.02881.1941 and status "connected"
$filteredServers = $arcServers | Where-Object {
    $_.Status -eq "connected" -and $_.OSType -eq $OSType
}
$filteredServers | ForEach-Object -Parallel {
    New-AzConnectedMachineRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -MachineName $_.Name `
        -RunCommandName "arcchrome01" `
        -Location $_.Location `
        -SourceScriptUri "https://raw.githubusercontent.com/lenvolk/images-using-azure-image-builder/refs/heads/main/LenVolk/Scripts/NanoLinux.sh" `
        -NoWait
}

# nano --version
# sudo dnf remove -y nano