<#
.SYNOPSIS
    Generates a comprehensive inventory of Azure Arc-enabled servers.

.DESCRIPTION
    This script authenticates to Azure, allows subscription selection, and exports Azure Arc-enabled server details
    to a CSV file. The inventory includes server name, resource group, location, status, OS type, and Arc agent version.

.NOTES
    File Name      : ARCcsvInventory.ps1
    Prerequisite   : Az.Accounts, Az.ConnectedMachine modules
    Version        : 1.0
    Date           : June 5, 2025
#>

# Check for required modules and install if missing
$requiredModules = @("Az.Accounts", "Az.ConnectedMachine", "Az.Resources")
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing required module: $module" -ForegroundColor Yellow
        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
    }
}

# Import modules
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.ConnectedMachine -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop

# Script variables
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$scriptPath = $PSScriptRoot
if (-not $scriptPath) {
    $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    if (-not $scriptPath) {
        $scriptPath = $PWD.Path
    }
}
$outputFile = Join-Path -Path $scriptPath -ChildPath "AzureArcInventory_$timestamp.csv"

# Check authentication status
$context = Get-AzContext -ErrorAction SilentlyContinue
if (-not $context) {
    Write-Host "Not authenticated to Azure. Please sign in..." -ForegroundColor Yellow
    try {
        Connect-AzAccount -ErrorAction Stop
    }
    catch {
        Write-Error "Authentication failed: $_"
        exit 1
    }
}

# Get available subscriptions and let user select one
$subscriptions = Get-AzSubscription -ErrorAction Stop
if ($subscriptions.Count -eq 0) {
    Write-Error "No subscriptions found for the authenticated account."
    exit 1
}
elseif ($subscriptions.Count -eq 1) {
    $selectedSubscription = $subscriptions[0]
    Write-Host "Using the only available subscription: $($selectedSubscription.Name) ($($selectedSubscription.Id))" -ForegroundColor Green
}
else {
    Write-Host "Available subscriptions:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $subscriptions.Count; $i++) {
        Write-Host "$($i+1). $($subscriptions[$i].Name) ($($subscriptions[$i].Id))"
    }
      $selection = 0
    do {
        try {
            $userInput = Read-Host "Enter the number of the subscription to use (1-$($subscriptions.Count))"
            $selection = [int]$userInput
        }
        catch {
            Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
        }
    } while (($selection -lt 1) -or ($selection -gt $subscriptions.Count))
    
    $selectedSubscription = $subscriptions[$selection-1]
    Write-Host "Selected subscription: $($selectedSubscription.Name)" -ForegroundColor Green
}

# Set the selected subscription as current context
Set-AzContext -Subscription $selectedSubscription.Id -ErrorAction Stop

# Get all Arc enabled servers
Write-Host "Retrieving Azure Arc enabled servers..." -ForegroundColor Cyan
try {
    $arcServers = Get-AzConnectedMachine -ErrorAction Stop
    
    if ($arcServers.Count -eq 0) {
        Write-Warning "No Azure Arc servers found in subscription $($selectedSubscription.Name)"
        exit 0
    }
    
    Write-Host "Found $($arcServers.Count) Arc-enabled servers." -ForegroundColor Green
      # Create inventory list
    $inventory = @()
    foreach ($server in $arcServers) {
        # Get tags for this server
        try {
            # Get the resource ID for the server
            $resourceId = $server.Id
            
            # Get tags for this resource
            $tags = Get-AzTag -ResourceId $resourceId -ErrorAction SilentlyContinue
            
            # Format tags as a string
            if ($tags -and $tags.Properties.TagsProperty.Keys.Count -gt 0) {
                $tagString = ($tags.Properties.TagsProperty.GetEnumerator() | ForEach-Object {
                    "$($_.Key):$($_.Value)"
                }) -join "; "
            }
            else {
                $tagString = "N/A"
            }
        }
        catch {
            Write-Verbose "Failed to retrieve tags for server $($server.Name): $_"
            $tagString = "N/A"
        }
        
        $inventory += [PSCustomObject]@{
            Name                = $server.Name
            ResourceGroupName   = $server.ResourceGroupName
            Location            = $server.Location
            Status              = $server.Status
            OSName              = $server.OSName
            OSType              = $server.OSType
            AgentVersion        = $server.AgentVersion
            LastStatusChange    = $server.LastStatusChange
            MachineFqdn         = $server.MachineFqdn
            Tags                = $tagString
            SubscriptionId      = $selectedSubscription.Id
            SubscriptionName    = $selectedSubscription.Name
        }
    }
    
    # Export to CSV
    $inventory | Export-Csv -Path $outputFile -NoTypeInformation -Force -Encoding UTF8
    Write-Host "Inventory exported to: $outputFile" -ForegroundColor Green
    
    # Display summary
    Write-Host "`nSummary of Arc-enabled servers by OS Type:" -ForegroundColor Cyan
    $inventory | Group-Object -Property OSType | ForEach-Object {
        Write-Host "$($_.Name): $($_.Count) servers"
    }
    
    Write-Host "`nSummary of Arc-enabled servers by Status:" -ForegroundColor Cyan
    $inventory | Group-Object -Property Status | ForEach-Object {
        Write-Host "$($_.Name): $($_.Count) servers"
    }
    
    # Show tag statistics
    Write-Host "`nTag Statistics:" -ForegroundColor Cyan
    $taggedServers = $inventory | Where-Object { $_.Tags -ne "N/A" } | Measure-Object | Select-Object -ExpandProperty Count
    $noTagServers = $inventory | Where-Object { $_.Tags -eq "N/A" } | Measure-Object | Select-Object -ExpandProperty Count
    Write-Host "Servers with tags: $taggedServers"
    Write-Host "Servers without tags: $noTagServers"
}
catch {
    Write-Error "Error retrieving Azure Arc servers: $_"
    exit 1
}
