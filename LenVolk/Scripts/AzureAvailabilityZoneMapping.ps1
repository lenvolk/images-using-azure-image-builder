# AzureAvailabilityZoneMapping.ps1
# This script maps Azure Availability Zones to their physical zone locations for all accessible subscriptions
# It requires the Az PowerShell module and sufficient Azure RBAC permissions

### Ref
# https://github.com/ElanShudnow/AzureCode/tree/main/PowerShell/AvailabilityZoneMapping

# AzureAvailabilityZoneMapping.ps1
# This script maps Azure Availability Zones to their physical zone locations for all accessible subscriptions
# It requires the Az PowerShell module and sufficient Azure RBAC permissions

<#
.SYNOPSIS
    Maps Azure Availability Zones to their physical zone locations for all accessible subscriptions.

.DESCRIPTION
    This script queries the Azure REST API to obtain information about the mapping between logical and 
    physical availability zones for specified regions across one or more Azure subscriptions.
    
.PARAMETER Region
    One or more Azure region names to check for availability zones.
    Example: -Region "eastus", "westeurope"
    
.PARAMETER SubscriptionId
    Specific Azure subscription ID to query. If not provided, all subscriptions will be checked.
    Example: -SubscriptionId "00000000-0000-0000-0000-000000000000"
    
.PARAMETER SearchPhysicalZone
    Filter results to show only availability zones matching the specified physical zone pattern.
    Example: -SearchPhysicalZone "australiaeast"
    
.PARAMETER ExportOnly
    When specified, results will only be exported to files without detailed console output.
    
.EXAMPLE
    # Check all regions in all subscriptions
    .\AzureAvailabilityZoneMapping.ps1
    
.EXAMPLE
    # Check specific regions in all subscriptions
    .\AzureAvailabilityZoneMapping.ps1 -Region "eastus", "westus2"
    
.EXAMPLE
    # Check all regions in a specific subscription
    .\AzureAvailabilityZoneMapping.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000"
    
.EXAMPLE
    # Search for a specific physical zone pattern
    .\AzureAvailabilityZoneMapping.ps1 -SearchPhysicalZone "australiaeast"
    
.EXAMPLE
    # Export only without console output
    .\AzureAvailabilityZoneMapping.ps1 -Region "eastus" -ExportOnly
#>

# Script Parameters
param (
    [Parameter(Mandatory = $false)]
    [string[]]$Region,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$SearchPhysicalZone,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportOnly
)

# Script Configuration
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$LogFile = Join-Path $PSScriptRoot "AzAvailabilityZoneMapping_$timestamp.log"
$OutputCsv = Join-Path $PSScriptRoot "AzAvailabilityZoneMapping_$timestamp.csv"
$ErrorActionPreference = "Stop"

# Function to write log messages
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

# Function to check if Az module is installed and available
function Test-AzModule {
    try {
        $azModule = Get-Module -Name Az -ListAvailable
        if ($null -eq $azModule) {
            Write-Log "Az PowerShell module is not installed. Please install it using: Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force" "Error"
            return $false
        }
        
        Write-Log "Az PowerShell module found (Version: $($azModule[0].Version))" "Info"
        return $true
    }    catch {
        Write-Log "Error checking Az module: $($_.Exception.Message)" "Error"
        return $false
    }
}

# Function to authenticate to Azure
function Connect-ToAzure {
    try {
        $context = Get-AzContext
        if ($null -eq $context) {
            Write-Log "No Azure context found. Initiating authentication..." "Info"
            Connect-AzAccount -ErrorAction Stop
        }
        else {
            Write-Log "Already authenticated as $($context.Account.Id) on subscription '$($context.Subscription.Name)'" "Info"
        }
        return $true
    }    catch {
        $errorMessage = $_.Exception.Message
        Write-Log "Authentication failed: $errorMessage" "Error"
        return $false
    }
}

# Function to get all available subscriptions
function Get-AllAzureSubscriptions {
    try {
        $subscriptions = Get-AzSubscription -ErrorAction Stop
        Write-Log "Found $($subscriptions.Count) subscription(s)" "Info"
        return $subscriptions
    }    catch {
        $errorMessage = $_.Exception.Message
        Write-Log "Error retrieving subscriptions: $errorMessage" "Error"
        return $null
    }
}

# Function to verify if a region exists and supports availability zones
function Test-RegionAvailabilityZoneSupport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Region,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )
    
    try {
        # Set the current subscription context
        $null = Set-AzContext -Subscription $SubscriptionId -ErrorAction Stop
        
        # Get all locations for this subscription
        $locations = Get-AzLocation -ErrorAction Stop
        
        # Check if region exists
        $regionExists = $locations | Where-Object { $_.Location -eq $Region }
        if (-not $regionExists) {
            return @{
                Exists = $false
                SupportsAZ = $false
                Message = "Region '$Region' does not exist or is not accessible in subscription '$SubscriptionId'."
            }
        }
        
        # Get available providers for the region
        $providers = Get-AzResourceProvider -Location $Region
        
        # Check if region supports availability zones
        # Most reliable way is to check through compute provider
        $computeProvider = $providers | Where-Object { $_.ProviderNamespace -eq "Microsoft.Compute" }
        $vmProvider = $computeProvider.ResourceTypes | Where-Object { $_.ResourceTypeName -eq "virtualMachines" }
        
        if ($vmProvider -and $vmProvider.Locations -contains $regionExists.Location) {
            if ($vmProvider.ZoneMappings -and $vmProvider.ZoneMappings.Count -gt 0) {
                return @{
                    Exists = $true
                    SupportsAZ = $true
                    Message = "Region '$Region' exists and supports availability zones."
                }
            }
            else {
                return @{
                    Exists = $true
                    SupportsAZ = $false
                    Message = "Region '$Region' exists but does not support availability zones."
                }
            }
        }
        
        # Fallback - if we can't determine AZ support from provider info,
        # assume it's supported if we've detected zones in the region via REST API
        return @{
            Exists = $true
            SupportsAZ = $true # We'll check this with the REST API anyway
            Message = "Region '$Region' exists. Availability zone support will be checked via REST API."
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        return @{
            Exists = $false
            SupportsAZ = $false
            Message = "Error verifying region '$Region': $errorMessage"
        }
    }
}

# Function to get physical zone mapping for a given region
# This uses the Azure REST API to retrieve the actual physical zone mappings
function Get-PhysicalZoneMapping {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Region,
        
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory = $false)]
        [int]$ZoneCount = 0
    )
      try {
        # Get an access token for the REST API call
        # Using -AsSecureString parameter to avoid the breaking change warning
        $secureToken = (Get-AzAccessToken -AsSecureString)
        
        # Convert SecureString to plain text for use in the header
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken.Token)
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        
        $headers = @{
            'Authorization' = "Bearer $token"
            'Content-Type' = 'application/json'
        }
        
        # Call the Azure REST API to get location information
        $apiVersion = "2022-12-01"
        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/locations?api-version=$apiVersion"
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        
        # Find our target region
        $locationData = $response.value | Where-Object { $_.name -eq $Region }
        
        if ($null -eq $locationData) {
            return @{
                "PhysicalMapping" = "No location data available for region $Region"
                "ZoneRedundancy" = "N/A"
                "AvailabilityZoneMappings" = @()
            }
        }
        
        # Extract availability zone mappings
        $azMappings = $locationData.availabilityZoneMappings
        
        if ($null -eq $azMappings -or $azMappings.Count -eq 0) {
            return @{
                "PhysicalMapping" = "No availability zone mappings found for region $Region"
                "ZoneRedundancy" = "N/A"
                "AvailabilityZoneMappings" = @()
            }
        }
        
        # Create a detailed mapping
        $physicalMappingDetails = $azMappings | ForEach-Object {
            [PSCustomObject]@{
                LogicalZone = $_.logicalZone
                PhysicalZone = $_.physicalZone
            }
        }
        
        return @{
            "PhysicalMapping" = "Availability Zones in $Region are mapped to physical zones"
            "ZoneRedundancy" = "Each zone has independent power, cooling, and networking infrastructure"
            "AvailabilityZoneMappings" = $physicalMappingDetails
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Log "Error retrieving physical zone mappings for region ${Region}: $errorMessage" "Warning"
        
        return @{
            "PhysicalMapping" = "Error retrieving physical mapping data for region $Region"
            "ZoneRedundancy" = "N/A"
            "AvailabilityZoneMappings" = @()
            "Error" = $errorMessage
        }
    }
}

# Function to get available regions and their AZ information for a subscription
function Get-RegionAvailabilityZones {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory = $false)]
        [string[]]$FilterRegions
    )
    
    try {
        # Set the current subscription context
        $null = Set-AzContext -Subscription $SubscriptionId -ErrorAction Stop
          # Get all locations for this subscription
        $locations = Get-AzLocation -ErrorAction Stop
        
        # Filter regions if specified
        if ($FilterRegions -and $FilterRegions.Count -gt 0) {
            $validRegions = @()
            foreach ($regionName in $FilterRegions) {
                # Check if region exists and supports AZs
                $regionCheck = Test-RegionAvailabilityZoneSupport -Region $regionName -SubscriptionId $SubscriptionId
                
                if ($regionCheck.Exists) {
                    if ($regionCheck.SupportsAZ) {
                        $foundRegion = $locations | Where-Object { $_.Location -eq $regionName }
                        if ($foundRegion) {
                            $validRegions += $foundRegion
                            Write-Log $regionCheck.Message "Info"
                        }
                    }
                    else {
                        Write-Log $regionCheck.Message "Warning"
                        Write-Log "For more information about regions that support Availability Zones, see: https://learn.microsoft.com/en-us/azure/reliability/availability-zones-region-support" "Info"
                    }
                }
                else {
                    Write-Log $regionCheck.Message "Warning"
                    $availableRegions = ($locations | Select-Object -ExpandProperty Location) -join ", "
                    Write-Log "Available regions in this subscription: $availableRegions" "Info"
                }
            }
            
            if ($validRegions.Count -eq 0) {
                Write-Log "No valid regions with Availability Zone support found for subscription '$SubscriptionId'. Skipping this subscription." "Warning"
                return @()
            }
            
            $locations = $validRegions
        }
        
        $results = @()
        
        foreach ($location in $locations) {
            try {
                # Get the availability zone count for this region
                # Note: We'll check VM resource providers as they commonly support AZs
                $vmSizes = Get-AzVMSize -Location $location.Location -ErrorAction SilentlyContinue
                
                # Determine if any VM sizes support Availability Zones
                $azSupport = $vmSizes | Where-Object { $_.NumberOfCores -gt 0 } | Where-Object { $null -ne $_.AvailabilityZones -and $_.AvailabilityZones.Count -gt 0 }
                
                $uniqueZones = @()
                if ($null -ne $azSupport -and $azSupport.Count -gt 0) {
                    $allZones = $azSupport.AvailabilityZones | ForEach-Object { $_ }
                    $uniqueZones = $allZones | Sort-Object -Unique
                }
                
                $zoneCount = if ($uniqueZones.Count -gt 0) { $uniqueZones.Count } else { 0 }
                
                # Get the physical zone mapping
                $physicalMapping = Get-PhysicalZoneMapping -Region $location.Location -SubscriptionId $SubscriptionId -ZoneCount $zoneCount
                
                # Create the result object
                $resultObj = [PSCustomObject]@{
                    RegionName = $location.DisplayName
                    RegionCode = $location.Location
                    AvailableZoneCount = $zoneCount
                    Zones = if ($uniqueZones.Count -gt 0) { $uniqueZones -join ', ' } else { "None" }
                    PhysicalMapping = $physicalMapping.PhysicalMapping
                    ZoneRedundancy = $physicalMapping.ZoneRedundancy
                }
                
                # Add physical zone mappings if available
                if ($physicalMapping.AvailabilityZoneMappings -and $physicalMapping.AvailabilityZoneMappings.Count -gt 0) {
                    $azMappingsFormatted = $physicalMapping.AvailabilityZoneMappings | ForEach-Object {
                        "Logical Zone $($_.LogicalZone) → Physical Zone: $($_.PhysicalZone)"
                    }
                    Add-Member -InputObject $resultObj -MemberType NoteProperty -Name "ZoneMappings" -Value ($azMappingsFormatted -join "; ")
                    
                    # Add individual mappings as separate properties for CSV export
                    foreach ($mapping in $physicalMapping.AvailabilityZoneMappings) {
                        Add-Member -InputObject $resultObj -MemberType NoteProperty -Name "Zone$($mapping.LogicalZone)_PhysicalZone" -Value $mapping.PhysicalZone
                    }
                }
                else {
                    Add-Member -InputObject $resultObj -MemberType NoteProperty -Name "ZoneMappings" -Value "No zone mappings found"
                }
                
                $results += $resultObj
            }            catch {
                $errorMessage = $_.Exception.Message
                Write-Log "Error retrieving AZ information for region $($location.DisplayName): $errorMessage" "Warning"
                $results += [PSCustomObject]@{
                    RegionName = $location.DisplayName
                    RegionCode = $location.Location
                    AvailableZoneCount = 0
                    Zones = "Error retrieving information"
                    PhysicalMapping = "Error retrieving information"
                    ZoneRedundancy = "Error retrieving information"
                    ZoneMappings = "Error: $errorMessage"
                }
            }
        }
          return $results    }    catch {
        $errorMessage = $_.Exception.Message
        Write-Log "Error retrieving region information for subscription ${SubscriptionId}: $errorMessage" "Error"
        return @()
    }
}

# Function to filter physical zones matching a pattern
function Find-PhysicalZoneMatches {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )
    
    $matchingRegions = @()
    
    foreach ($region in $Results) {
        # Extract mapping properties
        $propNames = $region.PSObject.Properties.Name | Where-Object { $_ -like "Zone*_PhysicalZone" }
        
        if ($propNames.Count -gt 0) {
            foreach ($prop in $propNames) {
                $physicalZone = $region.$prop
                if ($physicalZone -like "*$Pattern*") {
                    $logicalZone = $prop -replace "Zone", "" -replace "_PhysicalZone", ""
                    
                    $matchingRegions += [PSCustomObject]@{
                        RegionName = $region.RegionName
                        RegionCode = $region.RegionCode
                        LogicalZone = $logicalZone
                        PhysicalZone = $physicalZone
                    }
                }
            }
        }
    }
    
    return $matchingRegions
}

# Main script execution
try {
    Write-Log "Starting Azure Availability Zone mapping script" "Info"
    
    # Display welcome message with information about parameters passed
    Write-Host "`nAzure Availability Zone Mapping Tool" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "This script maps Azure Availability Zones to their physical zone locations`n" -ForegroundColor White
    
    if ($Region -and $Region.Count -gt 0) {
        Write-Host "Specified regions: $($Region -join ", ")" -ForegroundColor Yellow
    }
    else {
        Write-Host "No regions specified. Will check all available regions." -ForegroundColor Yellow
    }
    
    if ($SubscriptionId) {
        Write-Host "Processing single subscription: $SubscriptionId" -ForegroundColor Yellow
    }
    else {
        Write-Host "Processing all accessible subscriptions" -ForegroundColor Yellow
    }
    
    if ($SearchPhysicalZone) {
        Write-Host "Will search for physical zones matching: $SearchPhysicalZone" -ForegroundColor Yellow
    }
    
    if ($ExportOnly) {
        Write-Host "Export-only mode. Output will be written to files, limited console output." -ForegroundColor Yellow
    }
    
    Write-Host "`n"
    
    # Check for Az module
    if (-not (Test-AzModule)) {
        exit 1
    }
    
    # Authenticate to Azure
    if (-not (Connect-ToAzure)) {
        exit 1
    }
    
    # Get all subscriptions or filter by the provided subscription ID
    if ($SubscriptionId) {
        $subscriptions = Get-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction SilentlyContinue
        if (-not $subscriptions) {
            Write-Log "Subscription with ID '$SubscriptionId' not found or not accessible. Exiting." "Error"
            exit 1
        }
    }
    else {
        $subscriptions = Get-AllAzureSubscriptions
        if ($null -eq $subscriptions -or $subscriptions.Count -eq 0) {
            Write-Log "No subscriptions available. Exiting." "Error"
            exit 1
        }
    }
    
    # Create an array to store the results
    $allResults = @()
    
    # Process each subscription
    foreach ($subscription in $subscriptions) {
        # If specific subscription ID was provided, skip those that don't match
        if ($SubscriptionId -and $subscription.Id -ne $SubscriptionId) {
            continue
        }
        
        Write-Log "Processing subscription: $($subscription.Name) ($($subscription.Id))" "Info"
        
        # Get region AZ information for this subscription, filtering by specified regions if any
        $regionResults = Get-RegionAvailabilityZones -SubscriptionId $subscription.Id -FilterRegions $Region
        
        # Add subscription details to each result
        foreach ($result in $regionResults) {
            $result | Add-Member -MemberType NoteProperty -Name "SubscriptionName" -Value $subscription.Name
            $result | Add-Member -MemberType NoteProperty -Name "SubscriptionId" -Value $subscription.Id
            $allResults += $result
        }
        
        Write-Log "Completed processing for subscription: $($subscription.Name)" "Info"
    }
      # Display results in console
    Write-Log "Availability Zone Mapping Results:" "Info"
    
    # First display regions with AZ support
    Write-Log "Regions with Availability Zone support:" "Info"
    $regionsWithAZ = $allResults | Where-Object { $_.AvailableZoneCount -gt 0 } | Sort-Object RegionName
    
    foreach ($region in $regionsWithAZ) {
        Write-Host "`n=== Region: $($region.RegionName) ($($region.RegionCode)) ===" -ForegroundColor Cyan
        Write-Host "Available Zones: $($region.Zones)" -ForegroundColor Yellow
        Write-Host "Zone Redundancy: $($region.ZoneRedundancy)"
        
        if ($region.ZoneMappings -ne "No zone mappings found") {
            Write-Host "Physical Zone Mappings:" -ForegroundColor Green
            
            # Extract individual mappings
            $mappings = $region.ZoneMappings -split '; '
            foreach ($mapping in $mappings) {
                Write-Host "  $mapping"
            }
        }
        else {
            Write-Host "Physical Zone Mappings: Not available for this region" -ForegroundColor Gray
        }
    }
    
    # Export results to CSV
    $allResults | Export-Csv -Path $OutputCsv -NoTypeInformation
    Write-Log "Results exported to $OutputCsv" "Info"
    
    # Export physical zone mappings in JSON format (similar to az CLI output)
    $physicalZoneMappings = @()
    foreach ($region in $regionsWithAZ) {
        # Extract mapping properties
        $propNames = $region.PSObject.Properties.Name | Where-Object { $_ -like "Zone*_PhysicalZone" }
        if ($propNames.Count -gt 0) {
            $regionMapping = @{
                region = $region.RegionCode
                mappings = @()
            }
            
            foreach ($prop in $propNames) {
                $logicalZone = $prop -replace "Zone", "" -replace "_PhysicalZone", ""
                $regionMapping.mappings += @{
                    logicalZone = $logicalZone
                    physicalZone = $region.$prop
                }
            }
            
            $physicalZoneMappings += $regionMapping
        }
    }
      # Export JSON file with physical zone mappings
    $jsonOutputPath = Join-Path $PSScriptRoot "AzAvailabilityZoneMappings_$timestamp.json"
    $physicalZoneMappings | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonOutputPath
    Write-Log "Physical zone mappings exported to $jsonOutputPath" "Info"
    
    # If a search pattern was provided, filter and display matching physical zones
    if (-not [string]::IsNullOrEmpty($SearchPhysicalZone)) {
        Write-Host "`n====== PHYSICAL ZONE SEARCH RESULTS =====" -ForegroundColor Magenta
        Write-Host "Searching for physical zones matching pattern: $SearchPhysicalZone" -ForegroundColor Yellow
        
        $matches = Find-PhysicalZoneMatches -Results $allResults -Pattern $SearchPhysicalZone
        
        if ($matches.Count -eq 0) {
            Write-Host "No matching physical zones found." -ForegroundColor Red
        }
        else {
            Write-Host "Found $($matches.Count) matching physical zones:" -ForegroundColor Green
            $matches | Format-Table -AutoSize
            
            # Export search results
            $searchOutputPath = Join-Path $PSScriptRoot "AzAvailabilityZoneSearch_$SearchPhysicalZone`_$timestamp.json"
            $matches | ConvertTo-Json -Depth 4 | Out-File -FilePath $searchOutputPath
            Write-Log "Search results exported to $searchOutputPath" "Info"
        }
    }
    
    # Display summary statistics
    $totalSubscriptions = ($allResults | Select-Object -Property SubscriptionId -Unique).Count
    $totalRegions = ($allResults | Select-Object -Property RegionCode -Unique).Count
    $regionsWithAZCount = ($regionsWithAZ | Select-Object -Property RegionCode -Unique).Count
    
    Write-Host "`n====== SUMMARY ======" -ForegroundColor Magenta
    Write-Host "Subscriptions processed: $totalSubscriptions" -ForegroundColor Cyan
    Write-Host "Total regions checked: $totalRegions" -ForegroundColor Cyan
    Write-Host "Regions with Availability Zones: $regionsWithAZCount" -ForegroundColor Cyan
    Write-Host "Output files:" -ForegroundColor Cyan
    Write-Host "  - CSV: $OutputCsv" -ForegroundColor White
    Write-Host "  - JSON: $jsonOutputPath" -ForegroundColor White
    
    if (-not [string]::IsNullOrEmpty($SearchPhysicalZone)) {
        Write-Host "  - Search results: $searchOutputPath" -ForegroundColor White
    }
    
    Write-Log "Script execution completed successfully" "Info"
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Log "Unhandled error occurred: $errorMessage" "Error"
    exit 1
}
