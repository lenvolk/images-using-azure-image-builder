
param (
    [string]$ARCresourceGroup
)

# $ARCresourceGroup = "ARC"

Install-Module -Name Az.ConnectedMachine -Verbose -Force
Install-Module -Name Az.ResourceGraph -Verbose -Force


$arcServers = Get-AzConnectedMachine -ResourceGroupName $ARCresourceGroup

$filteredServers = $arcServers | Where-Object {
    $_.Status -eq "connected"
}

foreach ($server in $filteredServers) {
    if ($null -eq $server.Name) {
        Write-Host "Server name is null or empty for resource group: $($server.ResourceGroupName)"
    } else {
        Write-Host "Processing server: $($server.Name)"
        $RCom = Get-AzConnectedMachineRunCommand -ResourceGroupName $server.ResourceGroupName -MachineName $server.Name
        
        $RCom | ForEach-Object -Parallel {
            Write-Host "Removing command: $($_.Name) from server: $($using:server.Name)" -ForegroundColor Yellow
            Remove-AzConnectedMachineRunCommand `
             -RunCommandName $_.Name `
             -MachineName $($using:server.Name) `
             -ResourceGroupName $($using:server.ResourceGroupName)
        }

    }
}

# Get-Job -State Running
# # Get the status of a job by its ID
# $jobId = <YourJobId>
# $jobStatus = Get-Job -Id $jobId

# # Display the job status
# $jobStatus

# $jobs = Get-Job
# $results = $jobs | ForEach-Object { Receive-Job -Job $_; Remove-Job -Job $_ }