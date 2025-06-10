# Azure Resource Health Monitor Function
# This function runs daily to monitor Azure resources and check Service Health

using namespace System.Net

# Input bindings are passed in via param block.
param($Timer, $TriggerMetadata)

# Import required modules
Import-Module Az.Accounts -Force
Import-Module Az.Resources -Force
Import-Module Az.ResourceHealth -Force
Import-Module Az.Storage -Force

# Function to write logs with timestamps
function Write-LogMessage {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Output $logMessage
    
    # Also write to Application Insights if available
    if ($Level -eq 'Error') {
        Write-Error $logMessage
    } elseif ($Level -eq 'Warning') {
        Write-Warning $logMessage
    } else {
        Write-Host $logMessage
    }
}

# Function to authenticate using Managed Identity
function Connect-AzureWithManagedIdentity {
    try {
        Write-LogMessage "Connecting to Azure using Managed Identity..."
        
        # Connect using Managed Identity
        $context = Connect-AzAccount -Identity -ErrorAction Stop
        
        if ($context) {
            Write-LogMessage "Successfully connected to Azure using Managed Identity"
            Write-LogMessage "Account: $($context.Context.Account.Id)"
            Write-LogMessage "Tenant: $($context.Context.Tenant.Id)"
            return $true
        }
        return $false
    }
    catch {
        Write-LogMessage "Failed to connect using Managed Identity: $($_.Exception.Message)" -Level 'Error'
        return $false
    }
}

# Function to get or prompt for subscription selection
function Get-TargetSubscription {
    try {
        Write-LogMessage "Getting available subscriptions..."
        
        # Get all accessible subscriptions
        $subscriptions = Get-AzSubscription -ErrorAction Stop
        
        if ($subscriptions.Count -eq 0) {
            Write-LogMessage "No accessible subscriptions found" -Level 'Warning'
            return $null
        }
        
        Write-LogMessage "Found $($subscriptions.Count) accessible subscription(s)"
        
        # Check if we have a preferred subscription from app settings
        $preferredSubscriptionId = $env:PREFERRED_SUBSCRIPTION_ID
        
        if ($preferredSubscriptionId) {
            $targetSubscription = $subscriptions | Where-Object { $_.Id -eq $preferredSubscriptionId }
            if ($targetSubscription) {
                Write-LogMessage "Using preferred subscription: $($targetSubscription.Name) ($($targetSubscription.Id))"
                Set-AzContext -SubscriptionId $targetSubscription.Id | Out-Null
                return $targetSubscription
            }
            else {
                Write-LogMessage "Preferred subscription ID not found in accessible subscriptions" -Level 'Warning'
            }
        }
        
        # Use the first subscription as default (for automated scenarios)
        $defaultSubscription = $subscriptions[0]
        Write-LogMessage "Using default subscription: $($defaultSubscription.Name) ($($defaultSubscription.Id))"
        Set-AzContext -SubscriptionId $defaultSubscription.Id | Out-Null
        return $defaultSubscription
    }
    catch {
        Write-LogMessage "Error getting subscriptions: $($_.Exception.Message)" -Level 'Error'
        return $null
    }
}

# Function to inventory Azure resources
function Get-AzureResourceInventory {
    param([string]$SubscriptionId)
    
    try {
        Write-LogMessage "Starting resource inventory for subscription: $SubscriptionId"
        
        # Get all resources in the subscription
        $resources = Get-AzResource -ErrorAction Stop
        
        if ($resources.Count -eq 0) {
            Write-LogMessage "No resources found in subscription" -Level 'Warning'
            return @{}
        }
        
        Write-LogMessage "Found $($resources.Count) total resources"
        
        # Group resources by type and location
        $inventory = @{}
        $usedRegions = @()
        
        foreach ($resource in $resources) {
            $resourceType = $resource.ResourceType
            $location = $resource.Location
            
            # Track unique regions
            if ($location -and $location -notin $usedRegions) {
                $usedRegions += $location
            }
            
            # Group by resource type
            if (-not $inventory.ContainsKey($resourceType)) {
                $inventory[$resourceType] = @{
                    Count = 0
                    Locations = @()
                    Resources = @()
                }
            }
            
            $inventory[$resourceType].Count++
            if ($location -and $location -notin $inventory[$resourceType].Locations) {
                $inventory[$resourceType].Locations += $location
            }
            
            $inventory[$resourceType].Resources += @{
                Name = $resource.Name
                ResourceGroup = $resource.ResourceGroupName
                Location = $location
                Id = $resource.ResourceId
            }
        }
        
        Write-LogMessage "Resource inventory complete. Found $($inventory.Keys.Count) unique resource types across $($usedRegions.Count) regions"
        Write-LogMessage "Used regions: $($usedRegions -join ', ')"
        
        return @{
            Inventory = $inventory
            UsedRegions = $usedRegions
            TotalResources = $resources.Count
            SubscriptionId = $SubscriptionId
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        }
    }
    catch {
        Write-LogMessage "Error during resource inventory: $($_.Exception.Message)" -Level 'Error'
        return @{}
    }
}

# Function to check Azure Service Health
function Get-ServiceHealthEvents {
    param(
        [string]$SubscriptionId,
        [array]$UsedRegions,
        [hashtable]$ResourceInventory
    )
    
    try {
        Write-LogMessage "Checking Azure Service Health events..."
        
        # Get current time and 24 hours ago
        $endTime = Get-Date
        $startTime = $endTime.AddDays(-1)
        
        Write-LogMessage "Checking events from $($startTime.ToString('yyyy-MM-dd HH:mm:ss')) to $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        
        # Get service health events for the subscription
        $healthEvents = @()
        
        try {
            # Get resource health events for critical and warning levels
            $resourceHealthEvents = Get-AzResourceHealth -SubscriptionId $SubscriptionId -ErrorAction SilentlyContinue
            
            foreach ($event in $resourceHealthEvents) {
                if ($event.Properties.CurrentHealthStatus -in @('Warning', 'Critical', 'Unavailable')) {
                    $healthEvents += @{
                        Type = 'ResourceHealth'
                        Title = "Resource Health Issue: $($event.Name)"
                        Status = $event.Properties.CurrentHealthStatus
                        Description = $event.Properties.ReasonChronicity
                        ImpactedServices = @($event.ResourceType)
                        ImpactedRegions = @($event.Location)
                        StartTime = $event.Properties.OccurredTime
                        Level = if ($event.Properties.CurrentHealthStatus -eq 'Critical') { 'Critical' } else { 'Warning' }
                    }
                }
            }
        }
        catch {
            Write-LogMessage "Could not retrieve resource health events: $($_.Exception.Message)" -Level 'Warning'
        }
        
        # Filter events to only those affecting our resources and regions
        $relevantEvents = @()
        
        foreach ($event in $healthEvents) {
            $isRelevant = $false
            
            # Check if event affects any of our used regions
            foreach ($eventRegion in $event.ImpactedRegions) {
                if ($eventRegion -in $UsedRegions -or $eventRegion -eq 'Global') {
                    $isRelevant = $true
                    break
                }
            }
            
            # Check if event affects any of our deployed services
            if (-not $isRelevant) {
                foreach ($service in $event.ImpactedServices) {
                    # Map service names to resource types (simplified mapping)
                    $mappedTypes = @{
                        'Virtual Machines' = 'Microsoft.Compute/virtualMachines'
                        'Storage' = 'Microsoft.Storage/storageAccounts'
                        'App Service' = 'Microsoft.Web/sites'
                        'SQL Database' = 'Microsoft.Sql/servers'
                        'Key Vault' = 'Microsoft.KeyVault/vaults'
                        'Application Insights' = 'Microsoft.Insights/components'
                    }
                    
                    $resourceType = $mappedTypes[$service]
                    if ($resourceType -and $ResourceInventory.ContainsKey($resourceType)) {
                        $isRelevant = $true
                        break
                    }
                    
                    # Also check for partial matches
                    foreach ($inventoryType in $ResourceInventory.Keys) {
                        if ($inventoryType -like "*$service*" -or $service -like "*$inventoryType*") {
                            $isRelevant = $true
                            break
                        }
                    }
                    if ($isRelevant) { break }
                }
            }
            
            if ($isRelevant) {
                Write-LogMessage "Found relevant service health event: $($event.Title)" -Level 'Warning'
                $relevantEvents += $event
            }
        }
        
        Write-LogMessage "Found $($relevantEvents.Count) relevant service health events out of $($healthEvents.Count) total events"
        
        return $relevantEvents
    }
    catch {
        Write-LogMessage "Error checking service health: $($_.Exception.Message)" -Level 'Error'
        return @()
    }
}

# Function to save results to storage
function Save-ResultsToStorage {
    param(
        [hashtable]$Inventory,
        [array]$HealthEvents
    )
    
    try {
        $storageAccountName = $env:STORAGE_ACCOUNT_NAME
        if (-not $storageAccountName) {
            Write-LogMessage "Storage account name not configured" -Level 'Warning'
            return
        }
        
        Write-LogMessage "Saving results to storage account: $storageAccountName"
        
        # Create results object
        $results = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
            Inventory = $Inventory
            HealthEvents = $HealthEvents
            Summary = @{
                TotalResources = $Inventory.TotalResources
                ResourceTypes = $Inventory.Inventory.Keys.Count
                UsedRegions = $Inventory.UsedRegions.Count
                HealthIssues = $HealthEvents.Count
                CriticalIssues = ($HealthEvents | Where-Object { $_.Level -eq 'Critical' }).Count
                WarningIssues = ($HealthEvents | Where-Object { $_.Level -eq 'Warning' }).Count
            }
        }
        
        # Convert to JSON
        $jsonResults = $results | ConvertTo-Json -Depth 10
        
        # Get storage context using managed identity
        $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
        
        # Create blob name with timestamp
        $blobName = "health-monitor/$(Get-Date -Format 'yyyy-MM-dd-HHmmss')-results.json"
        
        # Upload to blob storage
        $blob = Set-AzStorageBlobContent -Container "logs" -Blob $blobName -BlobType Block -Context $storageContext -Content ([System.Text.Encoding]::UTF8.GetBytes($jsonResults)) -Force
        
        Write-LogMessage "Results saved to blob: $blobName"
        
        return $blobName
    }
    catch {
        Write-LogMessage "Error saving results to storage: $($_.Exception.Message)" -Level 'Error'
        return $null
    }
}

# Function to send alert notifications
function Send-AlertNotifications {
    param(
        [array]$HealthEvents,
        [hashtable]$Summary
    )
    
    try {
        if ($HealthEvents.Count -eq 0) {
            Write-LogMessage "No health events to alert on"
            return
        }
        
        Write-LogMessage "Preparing alert notifications for $($HealthEvents.Count) health events"
        
        # Create alert message
        $alertMessage = @"
Azure Resource Health Monitor Alert
=====================================

Summary:
- Total Health Issues: $($Summary.HealthIssues)
- Critical Issues: $($Summary.CriticalIssues)  
- Warning Issues: $($Summary.WarningIssues)
- Monitored Resources: $($Summary.TotalResources)
- Resource Types: $($Summary.ResourceTypes)
- Regions: $($Summary.UsedRegions)

Health Events:
"@

        foreach ($event in $HealthEvents) {
            $alertMessage += @"

[$($event.Level)] $($event.Title)
Description: $($event.Description)
Impacted Services: $($event.ImpactedServices -join ', ')
Impacted Regions: $($event.ImpactedRegions -join ', ')
Start Time: $($event.StartTime)
"@
        }
        
        Write-LogMessage "Alert message prepared" -Level 'Warning'
        Write-LogMessage $alertMessage -Level 'Warning'
        
        # Here you could integrate with:
        # - Azure Logic Apps for email notifications
        # - Teams webhook for Teams notifications  
        # - Azure Monitor Action Groups
        # - Custom notification endpoints
        
        return $alertMessage
    }
    catch {
        Write-LogMessage "Error sending alert notifications: $($_.Exception.Message)" -Level 'Error'
        return $null
    }
}

# Main execution function
function Invoke-HealthMonitor {
    try {
        Write-LogMessage "=== Azure Resource Health Monitor Started ==="
        
        # Step 1: Authenticate with Azure
        $authSuccess = Connect-AzureWithManagedIdentity
        if (-not $authSuccess) {
            throw "Failed to authenticate with Azure"
        }
        
        # Step 2: Get target subscription
        $targetSubscription = Get-TargetSubscription
        if (-not $targetSubscription) {
            throw "Failed to get target subscription"
        }
        
        # Step 3: Inventory resources
        $inventory = Get-AzureResourceInventory -SubscriptionId $targetSubscription.Id
        if ($inventory.Count -eq 0) {
            throw "Failed to get resource inventory"
        }
        
        # Step 4: Check service health
        $healthEvents = Get-ServiceHealthEvents -SubscriptionId $targetSubscription.Id -UsedRegions $inventory.UsedRegions -ResourceInventory $inventory.Inventory
        
        # Step 5: Save results
        $blobName = Save-ResultsToStorage -Inventory $inventory -HealthEvents $healthEvents
        
        # Step 6: Send alerts if there are issues
        if ($healthEvents.Count -gt 0) {
            $alertMessage = Send-AlertNotifications -HealthEvents $healthEvents -Summary $inventory
        }
        
        # Step 7: Summary
        Write-LogMessage "=== Health Monitor Completed Successfully ==="
        Write-LogMessage "Summary: $($inventory.TotalResources) resources, $($inventory.UsedRegions.Count) regions, $($healthEvents.Count) health issues"
        
        if ($healthEvents.Count -gt 0) {
            Write-LogMessage "ATTENTION: Found $($healthEvents.Count) health issues affecting your resources!" -Level 'Warning'
        } else {
            Write-LogMessage "All monitored services are healthy"
        }
        
        return @{
            Success = $true
            Summary = $inventory
            HealthEvents = $healthEvents
            BlobName = $blobName
        }
    }
    catch {
        Write-LogMessage "Health monitor failed: $($_.Exception.Message)" -Level 'Error'
        Write-LogMessage "Stack trace: $($_.ScriptStackTrace)" -Level 'Error'
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            StackTrace = $_.ScriptStackTrace
        }
    }
}

# Execute the main function
try {
    $result = Invoke-HealthMonitor
    
    # Return result for monitoring
    if ($result.Success) {
        Write-Output "Health monitor completed successfully"
    } else {
        Write-Error "Health monitor failed: $($result.Error)"
    }
}
catch {
    Write-Error "Unhandled error in health monitor: $($_.Exception.Message)"
}

Write-LogMessage "=== Azure Resource Health Monitor Function Completed ==="
