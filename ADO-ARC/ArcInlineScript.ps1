

# Ref https://learn.microsoft.com/en-us/azure/azure-arc/servers/manage-agent?tabs=windows#microsoft-update-configuration
# Install the required module
Install-Module Az.ConnectedMachine -Force

param (
    [string]$ARCresourceGroup,
    [string]$OSType
)

$ARCresourceGroup = 'ARC'
$OSType = 'Winodws'

$arcServers = Get-AzConnectedMachine -ResourceGroupName $ARCresourceGroup

$filteredServers = $arcServers | Where-Object {
    $_.Status -eq "connected" -and $_.OSType -eq $OSType
}

foreach ($server in $filteredServers) {
    $script = '$ServiceManager = (New-Object -com "Microsoft.Update.ServiceManager"); $ServiceManager.Services; $ServiceID = "7971f918-a847-4430-9279-4a52d1efe18d"; $ServiceManager.AddService2($ServiceId,7,"")'
    Start-Job -ScriptBlock {
        New-AzConnectedMachineRunCommand -ResourceGroupName $using:server.ResourceGroupName -SourceScript $using:script -RunCommandName "runGetInfo1" -MachineName $using:server.Name -Location $using:server.Location
    }
}
 
# Wait for all jobs to complete and get the results
$jobs = Get-Job
$results = $jobs | ForEach-Object { Receive-Job -Job $_; Remove-Job -Job $_ }

# to validate: Create an instance of the Microsoft.Update.ServiceManager COM object
$ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
 
# List all update services and their statuses
$services = $ServiceManager.Services | Select-Object Name, IsDefaultAUService
 
# Display the services
$services