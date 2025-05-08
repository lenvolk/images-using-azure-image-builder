# AzureEgressValidation.ps1
# This script validates Azure network egress configurations across all subscriptions
# It identifies VMs that may be impacted by changes to default outbound access
#
# IMPORTANT: Default outbound access for new deployments will be retired on September 30, 2025
# This script helps identify resources that need explicit outbound connectivity configured before the retirement date
# See: https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access
# https://techcommunity.microsoft.com/blog/coreinfrastructureandsecurityblog/how-to-identify-azure-resources-using-default-outbound-internet-access/4400755
# https://azure.microsoft.com/en-us/updates?id=default-outbound-access-for-vms-in-azure-will-be-retired-transition-to-a-new-method-of-internet-access


#region Script Parameters and Variables
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$ExportCsv, # Default is false
    
    [Parameter(Mandatory = $false)]
    [string]$ExportPath = "C:\temp",
    
    [Parameter(Mandatory = $false)]
    [string]$ExportFileName = "AzureEgressValidation_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

# Initialize results collection
$global:allImpactedWorkloads = @()
$global:processedSubscriptions = @()
$global:failedSubscriptions = @()
$startTime = Get-Date
#endregion

#region Helper Functions
function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
        default   { 'White' }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-AzureConnection {
    try {
        $context = Get-AzContext -ErrorAction Stop
        if ($null -eq $context.Account) {
            return $false
        }
        return $true
    }
    catch {
        return $false
    }
}

function Connect-ToAzure {
    try {
        Write-LogMessage "Checking Azure authentication status..." -Level Info
        
        if (-not (Test-AzureConnection)) {
            Write-LogMessage "You are not authenticated to Azure. Please sign in." -Level Warning
            $connection = Connect-AzAccount -ErrorAction Stop
            
            if ($null -eq $connection) {
                Write-LogMessage "Authentication failed or was cancelled. Exiting script." -Level Error
                exit 1
            }
            else {
                Write-LogMessage "Successfully authenticated to Azure as $($connection.Context.Account.Id)" -Level Success
            }
        }
        else {
            $currentContext = Get-AzContext
            Write-LogMessage "Already authenticated to Azure as $($currentContext.Account.Id)" -Level Success
            Write-LogMessage "Current subscription: $($currentContext.Subscription.Name) ($($currentContext.Subscription.Id))" -Level Info
        }
        return $true
    }
    catch {
        Write-LogMessage "Error during authentication: $_" -Level Error
        return $false
    }
}

function Export-ResultsToCsv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Ensure export directory exists
        $directory = [System.IO.Path]::GetDirectoryName($FilePath)
        if (-not (Test-Path -Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
            Write-LogMessage "Created directory: $directory" -Level Info
        }
        
        # Add execution summary to the results
        $executionSummary = [PSCustomObject]@{
            ReportType = "SUMMARY"
            ExecutionDateTime = $startTime
            TotalSubscriptions = $global:processedSubscriptions.Count + $global:failedSubscriptions.Count
            SuccessfulSubscriptions = $global:processedSubscriptions.Count
            FailedSubscriptions = $global:failedSubscriptions.Count
            TotalImpactedVMs = ($Results | Where-Object { $_.ReportType -ne "SUMMARY" }).Count
            ElapsedTime = "$(((Get-Date) - $startTime).ToString("hh\:mm\:ss"))"
        }
        
        $Results.Add($executionSummary) | Out-Null
        
        # Export to CSV
        $Results | Export-Csv -Path $FilePath -NoTypeInformation -Force
        
        Write-LogMessage "Results exported to $FilePath" -Level Success
        return $true
    }
    catch {
        Write-LogMessage "Error exporting results to CSV: $_" -Level Error
        return $false
    }
}

function Get-VmsInSubnet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]$VNet,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSSubnet]$Subnet
    )
    
    try {
        # Get all VMs in the resource group, including stopped/deallocated VMs
        # No -Status parameter is needed as Get-AzVM returns all VMs regardless of their power state
        $vms = Get-AzVM -ResourceGroupName $VNet.ResourceGroupName -Status -ErrorAction Stop
        $vmsInSubnet = @()
        
        # Filter VMs to find those in the subnet
        foreach ($vm in $vms) {
            # Handle null NetworkProfile or NetworkInterfaces
            if ($null -eq $vm.NetworkProfile -or $null -eq $vm.NetworkProfile.NetworkInterfaces) {
                Write-LogMessage "    Warning: VM $($vm.Name) has no network interfaces" -Level Warning
                continue
            }
            
            foreach ($nicRef in $vm.NetworkProfile.NetworkInterfaces) {
                $vmNics = Get-AzNetworkInterface -ResourceId $nicRef.Id -ErrorAction SilentlyContinue
                
                foreach ($nic in $vmNics) {
                    foreach ($ipConfig in $nic.IpConfigurations) {
                        if ($ipConfig.Subnet.Id -eq $Subnet.Id) {
                            # Add power state to VM object
                            $powerState = ($vm.Statuses | Where-Object { $_.Code -match 'PowerState' }).Code -replace 'PowerState/', ''
                            $vm | Add-Member -NotePropertyName PowerState -NotePropertyValue $powerState -Force -ErrorAction SilentlyContinue
                            $vmsInSubnet += $vm
                            break
                        }
                    }
                }
            }
        }
          # Also check for VMSS instances in this subnet
        try {
            # Get all VMSS across the subscription to be thorough (not just in this resource group)
            $vmssSet = Get-AzVmss -ResourceGroupName $VNet.ResourceGroupName -ErrorAction SilentlyContinue
            
            foreach ($vmss in $vmssSet) {
                # Check if this VMSS uses the subnet
                $vmssSubnetId = $null
                
                # Handle different VMSS network configurations
                if ($vmss.VirtualMachineProfile -and $vmss.VirtualMachineProfile.NetworkProfile) {
                    if ($vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations) {
                        foreach ($nicConfig in $vmss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations) {
                            if ($nicConfig.IpConfigurations) {
                                foreach ($ipConfig in $nicConfig.IpConfigurations) {
                                    if ($ipConfig.Subnet -and $ipConfig.Subnet.Id -eq $Subnet.Id) {
                                        $vmssSubnetId = $Subnet.Id
                                        break
                                    }
                                }
                            }
                            if ($vmssSubnetId) { break }
                        }
                    }
                }
                
                if ($vmssSubnetId -eq $Subnet.Id) {
                    # Get all VM instances including stopped ones
                    $vmssVMs = Get-AzVmssVM -ResourceGroupName $VNet.ResourceGroupName -VMScaleSetName $vmss.Name -InstanceView -ErrorAction SilentlyContinue
                    
                    # Add VMSS parent info to each instance
                    foreach ($vmssInstance in $vmssVMs) {
                        # Add VMSS properties to identify this is a VMSS instance
                        $vmssInstance | Add-Member -NotePropertyName IsVmssInstance -NotePropertyValue $true -Force -ErrorAction SilentlyContinue
                        $vmssInstance | Add-Member -NotePropertyName VmssName -NotePropertyValue $vmss.Name -Force -ErrorAction SilentlyContinue
                        $vmssInstance | Add-Member -NotePropertyName VmssCapacity -NotePropertyValue $vmss.Sku.Capacity -Force -ErrorAction SilentlyContinue
                        $vmssInstance | Add-Member -NotePropertyName VmssOrchestrationMode -NotePropertyValue $vmss.OrchestrationMode -Force -ErrorAction SilentlyContinue
                        
                        # Try to get power state
                        try {
                            $vmssInstanceView = Get-AzVmssVM -ResourceGroupName $VNet.ResourceGroupName -VMScaleSetName $vmss.Name -InstanceId $vmssInstance.InstanceId -InstanceView -ErrorAction SilentlyContinue
                            $powerState = ($vmssInstanceView.Statuses | Where-Object { $_.Code -match 'PowerState' }).Code -replace 'PowerState/', ''
                            $vmssInstance | Add-Member -NotePropertyName PowerState -NotePropertyValue $powerState -Force -ErrorAction SilentlyContinue
                        }
                        catch {
                            $vmssInstance | Add-Member -NotePropertyName PowerState -NotePropertyValue "Unknown" -Force -ErrorAction SilentlyContinue
                        }
                    }
                    
                    $vmsInSubnet += $vmssVMs
                    Write-LogMessage "    Found VMSS '$($vmss.Name)' with $($vmssVMs.Count) instances in this subnet" -Level Info
                }
            }
        }
        catch {
            Write-LogMessage "Warning: Error checking VMSS instances: $_" -Level Warning
        }
        
        # Include the power state in the log
        if ($vmsInSubnet.Count -gt 0) {
            Write-LogMessage "    VM count by power state: $($vmsInSubnet | Group-Object -Property PowerState | ForEach-Object { "$($_.Name): $($_.Count)" })" -Level Info
        }
        
        return $vmsInSubnet
    }
    catch {
        Write-LogMessage "Error finding VMs in subnet: $_" -Level Error
        return @()
    }
}
#endregion

#region Main Script Execution
# Get current context before script runs
$originalContext = Get-AzContext

# Verify authentication
if (-not (Connect-ToAzure)) {
    Write-LogMessage "Failed to authenticate to Azure. Exiting script." -Level Error
    exit 1
}

# Get all subscriptions
try {
    Write-LogMessage "Retrieving available Azure subscriptions..." -Level Info
    $subscriptions = Get-AzSubscription -ErrorAction Stop
    
    if ($null -eq $subscriptions -or $subscriptions.Count -eq 0) {
        Write-LogMessage "No subscriptions found. Please check your permissions and try again." -Level Error
        exit 1
    }
    
    Write-LogMessage "Found $($subscriptions.Count) subscriptions." -Level Success
}
catch {
    Write-LogMessage "Error retrieving subscriptions: $_" -Level Error
    exit 1
}

# Initialize results array for all subscriptions
$allResults = [System.Collections.ArrayList]@()

# Process each subscription
foreach ($subscription in $subscriptions) {
    Write-LogMessage "Processing subscription: $($subscription.Name) ($($subscription.Id))" -Level Info
    
    try {
        # Set context to current subscription
        Set-AzContext -Subscription $subscription.Id -ErrorAction Stop | Out-Null
        
        # Initialize results for this subscription
        $impactedWorkloads = @()
        
        # Get all VNets in subscription
        $vnets = Get-AzVirtualNetwork -ErrorAction Stop
        Write-LogMessage "Found $($vnets.Count) virtual networks in subscription $($subscription.Name)" -Level Info
          foreach ($vnet in $vnets) {
            Write-LogMessage "Analyzing VNet: $($vnet.Name) in resource group $($vnet.ResourceGroupName)" -Level Info
              foreach ($subnet in $vnet.Subnets) {
                $subnetIsCompliant = $false
                $subnetReason = ""
                $egressMethod = "Default" # Default, NATGateway, UDRtoNVA, UDRtoInternet, etc.
                
                Write-LogMessage "  Checking Subnet: $($subnet.Name)" -Level Info
                
                # 1. Check NAT Gateway (properly handle reference vs. full resource)
                $hasNatGateway = $false
                if ($null -ne $subnet.NatGateway -and $subnet.NatGateway.Id) {
                    # Try to get the NAT Gateway resource to confirm it exists
                    try {
                        $natGatewayId = $subnet.NatGateway.Id
                        # Extract resource group from the NAT Gateway ID
                        $natParts = $natGatewayId -split '/'
                        $natRgIndex = [array]::IndexOf($natParts, 'resourceGroups')
                        $natNameIndex = [array]::IndexOf($natParts, 'natGateways')
                        
                        if ($natRgIndex -ge 0 -and $natNameIndex -ge 0) {
                            $natRg = $natParts[$natRgIndex + 1]
                            $natName = $natParts[$natNameIndex + 1]
                            
                            $natGateway = Get-AzNatGateway -ResourceGroupName $natRg -Name $natName -ErrorAction SilentlyContinue
                            if ($natGateway) {                                $subnetIsCompliant = $true
                                $egressMethod = "NATGateway"
                                $subnetReason = "Associated with NAT Gateway: $natName"
                                Write-LogMessage "    Subnet is compliant: $subnetReason" -Level Success
                                continue # Next subnet
                            }
                        }
                    }
                    catch {
                        Write-LogMessage "    Warning: Error checking NAT Gateway: $_" -Level Warning
                    }
                }
                
                # 2. Check Route Table (UDR)
                $routeTable = $null
                if ($null -ne $subnet.RouteTable) {
                    try {
                        $routeTable = Get-AzRouteTable -ResourceId $subnet.RouteTable.Id -ErrorAction Stop
                    }
                    catch {
                        Write-LogMessage "    Warning: Cannot retrieve route table: $_" -Level Warning
                    }
                }
                
                if ($null -ne $routeTable) {
                    $internetRoute = $routeTable.Routes | Where-Object { $_.AddressPrefix -eq "0.0.0.0/0" }
                    
                    if ($null -ne $internetRoute) {                        if ($internetRoute.NextHopType -eq "VirtualAppliance") {
                            $subnetIsCompliant = $true
                            $egressMethod = "UDR to NVA"
                            $subnetReason = "UDR 0.0.0.0/0 to Virtual Appliance: $($internetRoute.NextHopIpAddress)"
                            Write-LogMessage "    Subnet is compliant: $subnetReason" -Level Success
                        }
                        elseif ($internetRoute.NextHopType -eq "Internet") {
                            $egressMethod = "UDR to Internet"
                            $subnetReason = "UDR 0.0.0.0/0 to Internet (will be impacted)"
                            Write-LogMessage "    Subnet will be impacted: $subnetReason" -Level Warning
                        }
                        else {
                            # Other specific next hop types for 0.0.0.0/0, may need analysis
                            $egressMethod = "UDR to $($internetRoute.NextHopType)"
                            $subnetReason = "UDR 0.0.0.0/0 to $($internetRoute.NextHopType) (not NVA, potentially default or other)"
                            Write-LogMessage "    Subnet may be impacted: $subnetReason" -Level Warning
                        }
                    }                    else {
                        # UDR exists, but no 0.0.0.0/0 route, so system route to Internet applies
                        $egressMethod = "Default (UDR without 0.0.0.0/0)"
                        $subnetReason = "UDR exists but no 0.0.0.0/0 route (uses system default)"
                        Write-LogMessage "    Subnet relies on default: $subnetReason" -Level Warning
                    }
                }
                else {
                    # No UDR, uses system route to Internet
                    $egressMethod = "Default (No UDR)"
                    $subnetReason = "No UDR associated (uses system default)"
                    Write-LogMessage "    Subnet relies on default: $subnetReason" -Level Warning
                }
                
                # If subnet is not compliant via NAT GW or UDR to NVA, check VMs
                if (-not $subnetIsCompliant) {
                    # Get VMs in this subnet (more targeted than getting all VMs)
                    $vmsInSubnet = Get-VmsInSubnet -VNet $vnet -Subnet $subnet
                    Write-LogMessage "    Found $($vmsInSubnet.Count) VMs in subnet" -Level Info
                      foreach ($vm in $vmsInSubnet) {
                        # Get network interfaces from VM's properties instead of using VMId parameter
                        $vmNics = @()
                        if ($null -ne $vm.NetworkProfile -and $null -ne $vm.NetworkProfile.NetworkInterfaces) {
                            foreach ($nicRef in $vm.NetworkProfile.NetworkInterfaces) {
                                $nic = Get-AzNetworkInterface -ResourceId $nicRef.Id -ErrorAction SilentlyContinue
                                if ($null -ne $nic) {
                                    $vmNics += $nic
                                }
                            }
                        }
                        $vmIsExplicitlyOutbound = $false
                        
                        foreach ($nic in $vmNics) {
                            # Check for Standard Public IP
                            $publicIPs = $nic.IpConfigurations | ForEach-Object { $_.PublicIpAddress }
                            
                            foreach ($publicIP in $publicIPs) {
                                if ($null -ne $publicIP) {
                                    # Get the actual public IP resource to check its SKU
                                    try {
                                        $pipResource = Get-AzPublicIpAddress -ResourceId $publicIP.Id -ErrorAction SilentlyContinue
                                        if ($null -ne $pipResource -and $pipResource.Sku.Name -eq "Standard") {
                                            $vmIsExplicitlyOutbound = $true
                                            break
                                        }
                                    }
                                    catch {
                                        Write-LogMessage "      Warning: Could not check public IP details: $_" -Level Warning
                                    }
                                }
                            }
                            
                            # Check for Standard Load Balancer with Outbound Rules
                            if (-not $vmIsExplicitlyOutbound) {
                                $lbBackendPools = $nic.IpConfigurations.LoadBalancerBackendAddressPools
                                
                                if ($null -ne $lbBackendPools) {
                                    foreach ($pool in $lbBackendPools) {
                                        try {
                                            # Parse the backend pool ID to get LB details
                                            $poolParts = $pool.Id -split '/'
                                            $lbIndex = [array]::IndexOf($poolParts, 'loadBalancers')
                                            
                                            if ($lbIndex -ge 0 -and $lbIndex + 1 -lt $poolParts.Length) {
                                                $lbName = $poolParts[$lbIndex + 1]
                                                $lbResourceGroup = $poolParts[[array]::IndexOf($poolParts, 'resourceGroups') + 1]
                                                
                                                # Get the load balancer
                                                $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $lbResourceGroup -ErrorAction SilentlyContinue
                                                
                                                # Check if it's a Standard SKU LB with outbound rules
                                                if ($null -ne $lb -and $lb.Sku.Name -eq "Standard" -and $null -ne $lb.OutboundRules -and $lb.OutboundRules.Count -gt 0) {
                                                    $vmIsExplicitlyOutbound = $true
                                                    break
                                                }
                                            }
                                        }
                                        catch {
                                            Write-LogMessage "      Warning: Error checking LB for outbound rules: $_" -Level Warning
                                        }
                                    }
                                }
                            }
                            
                            if ($vmIsExplicitlyOutbound) {
                                break  # No need to check other NICs if we found explicit outbound
                            }
                        }                        # Get additional VM properties
                        $vmType = if ($vm.PSObject.Properties.Name -contains "IsVmssInstance" -and $vm.IsVmssInstance) { "VMSS Instance" } else { "VM" }
                        $powerState = if ($vm.PSObject.Properties.Name -contains "PowerState") { $vm.PowerState } else { "Unknown" }
                        
                        # Include all VMs in the report, but mark if they're impacted or not
                        $isImpacted = -not $vmIsExplicitlyOutbound
                        $vmStatus = if ($isImpacted) { "Impacted" } else { "Compliant" }
                        $vmReason = if ($isImpacted) {
                            "VM in subnet with '$($subnetReason)' and lacks its own Standard PIP or LB outbound rule."
                        } else {
                            "VM has explicit outbound connectivity (Standard PIP or LB outbound rule)"
                        }
                        
                        $vmDetails = [PSCustomObject]@{
                            ReportType = "VM"
                            SubscriptionId = $subscription.Id
                            SubscriptionName = $subscription.Name
                            VMName = $vm.Name
                            VMId = $vm.Id
                            VMType = $vmType
                            PowerState = $powerState
                            SubnetName = $subnet.Name
                            VNetName = $vnet.Name
                            ResourceGroup = $vnet.ResourceGroupName
                            Location = $vnet.Location
                            EgressMethod = $egressMethod
                            Status = $vmStatus
                            Reason = $vmReason
                            IsImpacted = $isImpacted
                        }
                        
                        # Add to results array
                        $null = $allResults.Add($vmDetails)
                        
                        # Only add impacted workloads to the separate tracking array
                        if ($isImpacted) {
                            $impactedWorkloads += $vmDetails
                            Write-LogMessage "      Impacted VM: $($vm.Name) - $($vmDetails.Reason)" -Level Warning
                        }
                        else {
                            Write-LogMessage "      OK: VM $($vm.Name) has explicit outbound connectivity" -Level Success
                        }
                    }
                }
            }
        }
        
        # Record processed subscriptions
        $global:processedSubscriptions += $subscription.Id
        
        Write-LogMessage "Completed analysis of subscription $($subscription.Name). Found $($impactedWorkloads.Count) impacted workloads." -Level Info
    }
    catch {
        Write-LogMessage "Error processing subscription $($subscription.Name): $_" -Level Error
        $global:failedSubscriptions += $subscription.Id
    }
}

# Restore original context
if ($null -ne $originalContext) {
    Set-AzContext -Context $originalContext | Out-Null
    Write-LogMessage "Restored original context to subscription: $($originalContext.Subscription.Name)" -Level Info
}

# Display summary
$totalVMs = ($allResults | Where-Object { $_.ReportType -eq "VM" }).Count
$totalImpactedVMs = ($allResults | Where-Object { $_.ReportType -eq "VM" -and $_.IsImpacted -eq $true }).Count
$totalCompliantVMs = $totalVMs - $totalImpactedVMs

# Group VMs by type and power state
$vmsByType = $allResults | Where-Object { $_.ReportType -eq "VM" } | Group-Object -Property VMType
$vmsByPowerState = $allResults | Where-Object { $_.ReportType -eq "VM" } | Group-Object -Property PowerState

# Create detailed summary
Write-LogMessage "Analysis complete. Found $totalVMs total VMs across $($global:processedSubscriptions.Count) subscriptions." -Level Info
Write-LogMessage "  - Impacted VMs: $totalImpactedVMs" -Level Info
Write-LogMessage "  - Compliant VMs: $totalCompliantVMs" -Level Info
Write-LogMessage "VM types:" -Level Info
foreach ($typeGroup in $vmsByType) {
    Write-LogMessage "  - $($typeGroup.Name): $($typeGroup.Count)" -Level Info
}
Write-LogMessage "VM power states:" -Level Info
foreach ($stateGroup in $vmsByPowerState) {
    Write-LogMessage "  - $($stateGroup.Name): $($stateGroup.Count)" -Level Info
}

if ($global:failedSubscriptions.Count -gt 0) {
    Write-LogMessage "Failed to process $($global:failedSubscriptions.Count) subscriptions." -Level Warning
}

# Always export results to CSV unless explicitly disabled
if ($PSBoundParameters.ContainsKey('ExportCsv') -eq $false -or $ExportCsv) {
    $exportFullPath = Join-Path -Path $ExportPath -ChildPath $ExportFileName
    
    # Ensure export directory exists
    if (-not (Test-Path -Path $ExportPath)) {
        try {
            New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
            Write-LogMessage "Created export directory: $ExportPath" -Level Info
        }
        catch {
            Write-LogMessage "Failed to create export directory: $_" -Level Error
        }
    }
    
    # Ensure we have an ArrayList to avoid binding issues
    if ($null -eq $allResults) {
        $allResults = [System.Collections.ArrayList]@()
    } elseif ($allResults -isnot [System.Collections.ArrayList]) {
        $tempResults = [System.Collections.ArrayList]@()
        foreach ($item in $allResults) {
            $tempResults.Add($item) | Out-Null
        }
        $allResults = $tempResults
    }
    
    # Add a placeholder result if none found to avoid empty collection error
    if ($allResults.Count -eq 0) {
        $placeholderResult = [PSCustomObject]@{
            ReportType = "INFO"
            Message = "No impacted resources found"
            ExecutionDateTime = $startTime
            AnalysisDate = (Get-Date -Format "yyyy-MM-dd")
        }
        $allResults.Add($placeholderResult) | Out-Null
        Write-LogMessage "No impacted workloads found to export. Adding placeholder entry." -Level Info
    }
      try {
        # Calculate statistics
        $totalVMs = ($allResults | Where-Object { $_.ReportType -eq "VM" }).Count
        $totalImpactedVMs = ($allResults | Where-Object { $_.ReportType -eq "VM" -and $_.IsImpacted -eq $true }).Count
        $totalCompliantVMs = $totalVMs - $totalImpactedVMs
        $vmsByType = $allResults | Where-Object { $_.ReportType -eq "VM" } | Group-Object -Property VMType
        $standardVMs = ($vmsByType | Where-Object { $_.Name -eq "VM" }).Count
        $vmssInstances = ($vmsByType | Where-Object { $_.Name -eq "VMSS Instance" }).Count
        
        # Add execution summary with more detailed statistics
        $executionSummary = [PSCustomObject]@{
            ReportType = "SUMMARY"
            ExecutionDateTime = $startTime
            AnalysisDate = (Get-Date -Format "yyyy-MM-dd")
            TotalSubscriptions = $global:processedSubscriptions.Count + $global:failedSubscriptions.Count
            SuccessfulSubscriptions = $global:processedSubscriptions.Count
            FailedSubscriptions = $global:failedSubscriptions.Count
            TotalVMs = $totalVMs
            TotalImpactedVMs = $totalImpactedVMs
            TotalCompliantVMs = $totalCompliantVMs
            StandardVMs = $standardVMs
            VmssInstances = $vmssInstances
            ElapsedTime = "$(((Get-Date) - $startTime).ToString("hh\:mm\:ss"))"
        }
        
        $allResults.Add($executionSummary) | Out-Null
        
        # Export to CSV
        $allResults | Export-Csv -Path $exportFullPath -NoTypeInformation -Force
        
        Write-LogMessage "Results exported to: $exportFullPath" -Level Success
        
        # Offer to open the CSV file
        $openFile = Read-Host "Would you like to open the CSV file? (Y/N)"
        if ($openFile -eq "Y" -or $openFile -eq "y") {
            try {
                Invoke-Item -Path $exportFullPath
            }
            catch {
                Write-LogMessage "Could not open file: $_" -Level Error
            }
        }
    }
    catch {
        Write-LogMessage "Failed to export results to CSV: $_" -Level Error
    }
}
#endregion