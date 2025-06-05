<#
.SYNOPSIS
    Moves Azure Arc-enabled servers to different subscriptions based on tag values.

.DESCRIPTION
    This script reads a CSV inventory of Azure Arc-enabled servers, identifies servers with specific owner tags 
    ("owner:security" or "owner:on-prem-infra"), and moves them to corresponding resource groups 
    ("security" or "on-prem-infra") in a target subscription.

.PARAMETER CsvPath
    Path to the CSV inventory file containing Arc server information.
    If not specified, the script will look for the most recent AzureArcInventory CSV file in the script directory.

.PARAMETER TargetSubscriptionName
    Name of the target subscription where servers will be moved.
    If not specified, the script will prompt for input.

.NOTES
    File Name      : MoveByTag2Sub-RG.ps1
    Prerequisite   : Az.Accounts, Az.ConnectedMachine, Az.Resources modules
    Version        : 1.0
    Date           : June 5, 2025
    
    This script requires permissions to move resources between subscriptions.
    The executing user must have 'Owner' or 'Contributor' roles on both source and target subscriptions.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$CsvPath,
    
    [Parameter(Mandatory = $false)]
    [string]$TargetSubscriptionName
)

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
$logFile = Join-Path -Path $scriptPath -ChildPath "ArcServerMigration_$timestamp.log"
$reportFile = Join-Path -Path $scriptPath -ChildPath "ArcServerMigration_Report_$timestamp.csv"

# Setup logging
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
    
    # Write to log file
    Add-Content -Path $logFile -Value $logEntry
}

# Helper function to migrate a server
function Move-ArcServer {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Server,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetSubscriptionId
    )
    
    $reportEntry = [PSCustomObject]@{
        ServerName = $Server.Name
        SourceResourceGroup = $Server.ResourceGroupName
        SourceSubscription = $Server.SubscriptionName
        TargetResourceGroup = $TargetResourceGroup
        TargetSubscription = $TargetSubscriptionName
        Status = "Pending"
        ErrorMessage = ""
    }
    
    Write-Log "Processing server $($Server.Name) for migration to $TargetResourceGroup resource group..." "INFO"
    
    try {
        # Set context to source subscription if we have subscription ID
        if ($Server.SubscriptionId) {
            try {
                Set-AzContext -Subscription $Server.SubscriptionId -ErrorAction Stop
                Write-Log "Set context to subscription: $($Server.SubscriptionId)" "INFO"
            }
            catch {
                Write-Log "Failed to set context to subscription $($Server.SubscriptionId). Server might not be accessible: $_" "ERROR"
                $reportEntry.Status = "Failed"
                $reportEntry.ErrorMessage = "Cannot access source subscription: $_"
                return $reportEntry
            }
        }
        else {
            Write-Log "No subscription ID available for server $($Server.Name). Cannot proceed with migration." "ERROR"
            $reportEntry.Status = "Failed"
            $reportEntry.ErrorMessage = "Missing subscription ID for server"
            return $reportEntry
        }
        
        # Get resource ID
        try {
            $arcServer = Get-AzConnectedMachine -ResourceGroupName $Server.ResourceGroupName -Name $Server.Name -ErrorAction Stop
        }
        catch {
            Write-Log "Cannot find server $($Server.Name) in resource group $($Server.ResourceGroupName): $_" "ERROR"
            $reportEntry.Status = "Failed"
            $reportEntry.ErrorMessage = "Cannot find server: $_"
            return $reportEntry
        }
        
        # Return to target subscription context
        Set-AzContext -Subscription $TargetSubscriptionId -ErrorAction Stop
        
        # Check if a server with the same name already exists in the target resource group
        $existingServer = Get-AzConnectedMachine -ResourceGroupName $TargetResourceGroup -Name $Server.Name -ErrorAction SilentlyContinue
        if ($existingServer) {
            $reportEntry.Status = "Skipped"
            $reportEntry.ErrorMessage = "Server with the same name already exists in target resource group"
            Write-Log "Server $($Server.Name) already exists in target resource group '$TargetResourceGroup'. Skipping." "WARNING"
            return $reportEntry
        }
        
        # Move server to the target resource group
        Write-Log "Moving server $($Server.Name) to subscription $TargetSubscriptionName, resource group '$TargetResourceGroup'..." "INFO"
        
        # Use the Move-AzResource command to move the server
        $resourceId = $arcServer.Id
        Move-AzResource -DestinationSubscriptionId $TargetSubscriptionId -DestinationResourceGroupName $TargetResourceGroup -ResourceId $resourceId -Force
        
        $reportEntry.Status = "Success"
        Write-Log "Successfully moved server $($Server.Name) to $TargetResourceGroup resource group" "SUCCESS"
    }
    catch {
        $reportEntry.Status = "Failed"
        $reportEntry.ErrorMessage = $_.Exception.Message
        Write-Log "Failed to move server $($Server.Name): $_" "ERROR"
    }
    
    return $reportEntry
}

# Start logging
Write-Log "Starting Arc server migration process" "INFO"
Write-Log "Log file: $logFile" "INFO"

# Check authentication status
$context = Get-AzContext -ErrorAction SilentlyContinue
if (-not $context) {
    Write-Log "Not authenticated to Azure. Please sign in..." "WARNING"
    try {
        Connect-AzAccount -ErrorAction Stop
        $context = Get-AzContext
    }
    catch {
        Write-Log "Authentication failed: $_" "ERROR"
        exit 1
    }
}
Write-Log "Authenticated as $($context.Account.Id)" "SUCCESS"

# Find CSV file if not specified
if (-not $CsvPath) {
    Write-Log "No CSV path specified, looking for most recent AzureArcInventory file..." "INFO"
    $csvFiles = Get-ChildItem -Path $scriptPath -Filter "AzureArcInventory_*.csv" | Sort-Object LastWriteTime -Descending
    
    if ($csvFiles.Count -eq 0) {
        Write-Log "No AzureArcInventory CSV files found in the script directory. Please run ARCcsvInventory.ps1 first or provide a path." "ERROR"
        exit 1
    }
    
    $CsvPath = $csvFiles[0].FullName
    Write-Log "Using most recent CSV file: $CsvPath" "SUCCESS"
}

# Verify CSV file exists
if (-not (Test-Path -Path $CsvPath)) {
    Write-Log "CSV file not found: $CsvPath" "ERROR"
    exit 1
}

# Read the CSV file
try {
    $arcServers = Import-Csv -Path $CsvPath -ErrorAction Stop
    Write-Log "Successfully imported $($arcServers.Count) servers from CSV" "SUCCESS"
}
catch {
    Write-Log "Failed to read CSV file: $_" "ERROR"
    exit 1
}

# Check and map CSV columns dynamically
Write-Log "Analyzing CSV structure..." "INFO"
$csvColumns = $arcServers[0].PSObject.Properties.Name
Write-Log "Found columns in CSV: $($csvColumns -join ', ')" "INFO"

# Define possible column name variations
$columnMappings = @{
    "Name" = @("Name", "ServerName", "MachineName", "ComputerName", "ArcServer")
    "ResourceGroupName" = @("ResourceGroupName", "ResourceGroup", "RG", "ResGroup")
    "Tags" = @("Tags", "Tag", "AzureTags", "ResourceTags")
    "SubscriptionId" = @("SubscriptionId", "SubId", "SubscriptionID", "AzureSubscriptionId")
    "SubscriptionName" = @("SubscriptionName", "SubName", "AzureSubscriptionName")
}

# Create a mapping of actual columns to standard names
$actualColumnMappings = @{}
foreach ($standardColumn in $columnMappings.Keys) {
    $foundColumn = $null
    foreach ($possibleName in $columnMappings[$standardColumn]) {
        if ($csvColumns -contains $possibleName) {
            $foundColumn = $possibleName
            break
        }
    }
    
    if ($foundColumn) {
        $actualColumnMappings[$standardColumn] = $foundColumn
        Write-Log "Mapped '$standardColumn' to CSV column '$foundColumn'" "INFO"
    }
    else {
        Write-Log "Could not find a column matching '$standardColumn' in the CSV" "WARNING"
    }
}

# Determine if we need to query additional information from Azure
$needsAzureQueries = $actualColumnMappings.Count -lt $columnMappings.Count

# Enrich server data if needed
if ($needsAzureQueries) {
    Write-Log "Some required information is missing from CSV. Will query Azure for additional details." "INFO"
    $enrichedServers = @()
    
    foreach ($server in $arcServers) {
        $serverName = $null
        $resourceGroup = $null
        $serverTags = "N/A"
        $subscriptionId = $null
        $subscriptionName = $null
        
        # Get name from CSV if available
        if ($actualColumnMappings.ContainsKey("Name")) {
            $serverName = $server.($actualColumnMappings["Name"])
        }
        
        # Get resource group from CSV if available
        if ($actualColumnMappings.ContainsKey("ResourceGroupName")) {
            $resourceGroup = $server.($actualColumnMappings["ResourceGroupName"])
        }
        
        # Get tags from CSV if available
        if ($actualColumnMappings.ContainsKey("Tags")) {
            $serverTags = $server.($actualColumnMappings["Tags"])
        }
        
        # Get subscription info from CSV if available
        if ($actualColumnMappings.ContainsKey("SubscriptionId")) {
            $subscriptionId = $server.($actualColumnMappings["SubscriptionId"])
        }
        
        if ($actualColumnMappings.ContainsKey("SubscriptionName")) {
            $subscriptionName = $server.($actualColumnMappings["SubscriptionName"])
        }
        
        # If we're missing critical information, try to query Azure
        if (-not $serverName -or -not $resourceGroup) {
            Write-Log "Server entry is missing name or resource group. Skipping: $($server | ConvertTo-Json -Compress)" "WARNING"
            continue
        }
        
        if (-not $subscriptionId -or -not $subscriptionName -or $serverTags -eq "N/A") {
            Write-Log "Server '$serverName' is missing subscription or tag information. Querying Azure..." "INFO"
            
            # Try to find the Arc server in the current subscription context
            $currentSubscription = (Get-AzContext).Subscription
            
            try {
                $arcServer = Get-AzConnectedMachine -Name $serverName -ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue
                
                if ($arcServer) {
                    # Get tags if missing
                    if ($serverTags -eq "N/A") {
                        $resourceTags = Get-AzTag -ResourceId $arcServer.Id -ErrorAction SilentlyContinue
                        if ($resourceTags -and $resourceTags.Properties.TagsProperty.Keys.Count -gt 0) {
                            $serverTags = ($resourceTags.Properties.TagsProperty.GetEnumerator() | ForEach-Object {
                                "$($_.Key):$($_.Value)"
                            }) -join "; "
                        }
                    }
                    
                    # Get subscription info if missing
                    if (-not $subscriptionId) {
                        $subscriptionId = $currentSubscription.Id
                    }
                    
                    if (-not $subscriptionName) {
                        $subscriptionName = $currentSubscription.Name
                    }
                    
                    Write-Log "Retrieved additional information for server '$serverName'" "SUCCESS"
                }
                else {
                    Write-Log "Could not find server '$serverName' in resource group '$resourceGroup'. It may exist in a different subscription." "WARNING"
                }
            }
            catch {
                Write-Log "Error querying Azure for server '$serverName': $_" "ERROR"
            }
        }
        
        # Add enriched server data to our collection
        $enrichedServers += [PSCustomObject]@{
            Name = $serverName
            ResourceGroupName = $resourceGroup
            Tags = $serverTags
            SubscriptionId = $subscriptionId
            SubscriptionName = $subscriptionName
        }
    }
    
    # Replace the original server collection with our enriched data
    $arcServers = $enrichedServers
    Write-Log "Enriched server data with additional information from Azure." "SUCCESS"
}

# Filter servers with the specified tags
$securityServers = $arcServers | Where-Object { $_.Tags -like "*owner:security*" }
$onPremInfraServers = $arcServers | Where-Object { $_.Tags -like "*owner:on-prem-infra*" }

$totalTaggedServers = $securityServers.Count + $onPremInfraServers.Count
if ($totalTaggedServers -eq 0) {
    Write-Log "No servers found with 'owner:security' or 'owner:on-prem-infra' tags" "WARNING"
    exit 0
}

Write-Log "Found $($securityServers.Count) servers with 'owner:security' tag" "INFO"
Write-Log "Found $($onPremInfraServers.Count) servers with 'owner:on-prem-infra' tag" "INFO"

# Get target subscription if not provided
if (-not $TargetSubscriptionName) {
    $subscriptions = Get-AzSubscription -ErrorAction Stop
    
    Write-Host "`nAvailable subscriptions:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $subscriptions.Count; $i++) {
        Write-Host "$($i+1). $($subscriptions[$i].Name) ($($subscriptions[$i].Id))"
    }
    
    $selection = 0
    do {
        try {
            $userInput = Read-Host "`nEnter the number of the target subscription (1-$($subscriptions.Count))"
            $selection = [int]$userInput
        }
        catch {
            Write-Log "Invalid input. Please enter a number." "ERROR"
        }
    } while (($selection -lt 1) -or ($selection -gt $subscriptions.Count))
    
    $targetSubscription = $subscriptions[$selection-1]
    $TargetSubscriptionName = $targetSubscription.Name
    $TargetSubscriptionId = $targetSubscription.Id
    
    Write-Log "Selected target subscription: $TargetSubscriptionName ($TargetSubscriptionId)" "SUCCESS"
}
else {
    # Find subscription by name
    try {
        $targetSubscription = Get-AzSubscription -SubscriptionName $TargetSubscriptionName -ErrorAction Stop
        $TargetSubscriptionId = $targetSubscription.Id
        Write-Log "Found target subscription: $TargetSubscriptionName ($TargetSubscriptionId)" "SUCCESS"
    }
    catch {
        Write-Log "Failed to find subscription with name: $TargetSubscriptionName" "ERROR"
        exit 1
    }
}

# Set context to target subscription to check/create resource groups
Set-AzContext -Subscription $TargetSubscriptionId -ErrorAction Stop
Write-Log "Context set to target subscription" "SUCCESS"

# Check/create security resource group
$securityRG = Get-AzResourceGroup -Name "security" -ErrorAction SilentlyContinue
if (-not $securityRG) {
    Write-Log "Resource group 'security' not found in target subscription. Creating..." "INFO"
    try {
        $location = Read-Host "Enter location for the 'security' resource group (e.g., eastus)"
        $securityRG = New-AzResourceGroup -Name "security" -Location $location -ErrorAction Stop
        Write-Log "Created resource group 'security' in $location" "SUCCESS"
    }
    catch {
        Write-Log "Failed to create resource group 'security': $_" "ERROR"
        exit 1
    }
}
else {
    Write-Log "Found existing resource group 'security'" "SUCCESS"
}

# Check/create on-prem-infra resource group
$onPremInfraRG = Get-AzResourceGroup -Name "on-prem-infra" -ErrorAction SilentlyContinue
if (-not $onPremInfraRG) {
    Write-Log "Resource group 'on-prem-infra' not found in target subscription. Creating..." "INFO"
    try {
        # Use same location as security RG if already created
        if ($securityRG) {
            $location = $securityRG.Location
        }
        else {
            $location = Read-Host "Enter location for the 'on-prem-infra' resource group (e.g., eastus)"
        }
        
        $onPremInfraRG = New-AzResourceGroup -Name "on-prem-infra" -Location $location -ErrorAction Stop
        Write-Log "Created resource group 'on-prem-infra' in $location" "SUCCESS"
    }
    catch {
        Write-Log "Failed to create resource group 'on-prem-infra': $_" "ERROR"
        exit 1
    }
}
else {
    Write-Log "Found existing resource group 'on-prem-infra'" "SUCCESS"
}

# Prepare migration report
$migrationReport = @()

# Process security servers
foreach ($server in $securityServers) {
    $reportEntry = Move-ArcServer -Server $server -TargetResourceGroup "security" -TargetSubscriptionId $TargetSubscriptionId
    $migrationReport += $reportEntry
}

# Process on-prem-infra servers
foreach ($server in $onPremInfraServers) {
    $reportEntry = Move-ArcServer -Server $server -TargetResourceGroup "on-prem-infra" -TargetSubscriptionId $TargetSubscriptionId
    $migrationReport += $reportEntry
}

# Export migration report
$migrationReport | Export-Csv -Path $reportFile -NoTypeInformation -Force -Encoding UTF8
Write-Log "Migration report exported to: $reportFile" "SUCCESS"

# Summary of migration results
$successful = $migrationReport | Where-Object { $_.Status -eq "Success" } | Measure-Object | Select-Object -ExpandProperty Count
$skipped = $migrationReport | Where-Object { $_.Status -eq "Skipped" } | Measure-Object | Select-Object -ExpandProperty Count
$failed = $migrationReport | Where-Object { $_.Status -eq "Failed" } | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "`n=== Migration Summary ===" -ForegroundColor Cyan
Write-Host "Total servers processed: $($migrationReport.Count)" -ForegroundColor Cyan
Write-Host "- Successfully migrated: $successful" -ForegroundColor Green
Write-Host "- Skipped: $skipped" -ForegroundColor Yellow
Write-Host "- Failed: $failed" -ForegroundColor Red
Write-Host "See detailed report in: $reportFile" -ForegroundColor Cyan
Write-Host "See log file: $logFile" -ForegroundColor Cyan

Write-Log "Migration process completed." "INFO"
