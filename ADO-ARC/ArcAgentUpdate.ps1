
param (
    [string]$ARCresourceGroup,
    [string]$OSType,
    [string]$ArcAgentVer
)

Install-Module -Name Az.ConnectedMachine -Verbose -Force
Install-Module -Name Az.ResourceGraph -Verbose -Force


Write-Host "Looking for $OSType Servers in the RG $ARCresourceGroup which have agent version less than: $ArcAgentVer" -ForegroundColor Yellow

$arcServers = Get-AzConnectedMachine -ResourceGroupName $ARCresourceGroup
# Filter servers with agent version below 1.48.02881.1941 and status "connected"
$filteredServers = $arcServers | Where-Object {
    [version]$_.AgentVersion -lt [version]$ArcAgentVer -and $_.Status -eq "connected" -and $_.OSType -eq $OSType
    #Write-Host "Servers: $($_.Name) with arc agent version: $_.AgentVersion" -ForegroundColor Yellow
}

foreach ($server in $filteredServers) {
    New-AzConnectedMachineRunCommand -ResourceGroupName $server.ResourceGroupName `
    -MachineName $server.Name `
    -RunCommandName "arcagupd01" `
    -Location $server.Location `
    -SourceScriptUri "https://raw.githubusercontent.com/lenvolk/images-using-azure-image-builder/refs/heads/main/LenVolk/ARC/arcagent.ps1" `
    -AsJob
}
