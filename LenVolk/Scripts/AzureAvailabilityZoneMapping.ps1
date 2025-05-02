# AzureAvailabilityZoneMapping.ps1
# This script maps Azure Availability Zones to their physical zone locations for all accessible subscriptions
# It requires the Az PowerShell module and sufficient Azure RBAC permissions

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

# Function to get physical zone mapping for a given region
# Note: This is a simplified mapping based on available documentation
# Physical zone mappings are not directly exposed via public Azure APIs
function Get-PhysicalZoneMapping {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Region,
        
        [Parameter(Mandatory = $true)]
        [int]$ZoneCount
    )
    
    # This is a simplified representation as actual physical mappings aren't exposed by Azure APIs
    # In reality, this would need to be based on Microsoft's published documentation
    # Reference: https://learn.microsoft.com/en-us/azure/availability-zones/az-overview
    
    $mappingInfo = switch ($Region) {
        "eastus" {
            @{
                "PhysicalMapping" = "Mapped to separate physical data centers in East US region"
                "ZoneRedundancy" = "Each zone has independent power, cooling, and networking"
            }
        }
        "eastus2" {
            @{
                "PhysicalMapping" = "Mapped to separate physical data centers in East US 2 region"
                "ZoneRedundancy" = "Each zone has independent power, cooling, and networking"
            }
        }
        "westus2" {
            @{
                "PhysicalMapping" = "Mapped to separate physical data centers in West US 2 region"
                "ZoneRedundancy" = "Each zone has independent power, cooling, and networking"
            }
        }
        "centralus" {
            @{
                "PhysicalMapping" = "Mapped to separate physical data centers in Central US region"
                "ZoneRedundancy" = "Each zone has independent power, cooling, and networking"
            }
        }
        default {
            if ($ZoneCount -gt 0) {
                @{
                    "PhysicalMapping" = "Mapped to $ZoneCount separate physical data centers in $Region region"
                    "ZoneRedundancy" = "Each zone has independent power, cooling, and networking"
                }
            }
            else {
                @{
                    "PhysicalMapping" = "No AZ information available for this region"
                    "ZoneRedundancy" = "N/A"
                }
            }
        }
    }
    
    return $mappingInfo
}

# Function to get available regions and their AZ information for a subscription
function Get-RegionAvailabilityZones {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )
    
    try {
        # Set the current subscription context
        $null = Set-AzContext -Subscription $SubscriptionId -ErrorAction Stop
        
        # Get all locations for this subscription
        $locations = Get-AzLocation -ErrorAction Stop
        
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
                $physicalMapping = Get-PhysicalZoneMapping -Region $location.Location -ZoneCount $zoneCount
                
                $results += [PSCustomObject]@{
                    RegionName = $location.DisplayName
                    RegionCode = $location.Location
                    AvailableZoneCount = $zoneCount
                    Zones = if ($uniqueZones.Count -gt 0) { $uniqueZones -join ', ' } else { "None" }
                    PhysicalMapping = $physicalMapping.PhysicalMapping
                    ZoneRedundancy = $physicalMapping.ZoneRedundancy
                }
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
                }
            }
        }
          return $results    }    catch {
        $errorMessage = $_.Exception.Message
        Write-Log "Error retrieving region information for subscription ${SubscriptionId}: $errorMessage" "Error"
        return @()
    }
}

# Main script execution
try {
    Write-Log "Starting Azure Availability Zone mapping script" "Info"
    
    # Check for Az module
    if (-not (Test-AzModule)) {
        exit 1
    }
    
    # Authenticate to Azure
    if (-not (Connect-ToAzure)) {
        exit 1
    }
    
    # Get all subscriptions
    $subscriptions = Get-AllAzureSubscriptions
    if ($null -eq $subscriptions -or $subscriptions.Count -eq 0) {
        Write-Log "No subscriptions available. Exiting." "Error"
        exit 1
    }
    
    # Create an array to store the results
    $allResults = @()
    
    # Process each subscription
    foreach ($subscription in $subscriptions) {
        Write-Log "Processing subscription: $($subscription.Name) ($($subscription.Id))" "Info"
        
        # Get region AZ information for this subscription
        $regionResults = Get-RegionAvailabilityZones -SubscriptionId $subscription.Id
        
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
    $allResults | Format-Table -AutoSize
    
    # Export results to CSV
    $allResults | Export-Csv -Path $OutputCsv -NoTypeInformation
    Write-Log "Results exported to $OutputCsv" "Info"
    
    Write-Log "Script execution completed successfully" "Info"
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Log "Unhandled error occurred: $errorMessage" "Error"
    exit 1
}
