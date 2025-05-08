<#
.SYNOPSIS
    Identifies Azure VMs and VM Scale Sets that might be using default outbound access,
    which is scheduled for retirement.
.DESCRIPTION
    This script iterates through Azure subscriptions, resource groups, VMs, and VM Scale Sets
    to check their network configurations for explicit outbound connectivity methods.
    It flags resources that appear to be relying on the implicit default outbound SNAT.

    Explicit outbound methods checked:
    1. NAT Gateway associated with the subnet.
    2. User Defined Route (UDR) for 0.0.0.0/0 to a Network Virtual Appliance (NVA).
    3. Standard SKU Public IP address directly associated with the VM/VMSS NIC.
    4. VM/VMSS instance is in the backend pool of a Standard SKU Public Load Balancer
       that has defined outbound rules.

    The script generates a report of potentially affected resources.

.NOTES
    Version: 2.1 (Corrected parser error, improved PowerState retrieval)
    Original Author: Len Volk (GitHub: lenvolk)
    Modified by: AI Assistant based on user feedback.

    Prerequisites:
    - Azure PowerShell 'Az' module installed and updated.
    - Connected to Azure with Connect-AzAccount.
    - Sufficient permissions to read network and compute resources.

    Considerations for large environments:
    - This script uses Get-Az* cmdlets iteratively, which can be slow.
    - For faster initial assessments in large environments, Azure Resource Graph queries are recommended.

    Ref See: https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access
             https://techcommunity.microsoft.com/blog/coreinfrastructureandsecurityblog/how-to-identify-azure-resources-using-default-outbound-internet-access/4400755
             https://azure.microsoft.com/en-us/updates?id=default-outbound-access-for-vms-in-azure-will-be-retired-transition-to-a-new-method-of-internet-access
#>

param (
    [Parameter(Mandatory = $false, HelpMessage = "Optional: Specify a single Subscription ID to scan. If not provided, all accessible subscriptions will be scanned.")]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false, HelpMessage = "Optional: Path to export the report as a CSV file. Example: C:\temp\EgressReport.csv")]
    [string]$CsvExportPath
)

$ErrorActionPreference = "SilentlyContinue" # Can be changed to "Stop" for debugging

# --- Script Initialization ---
Write-Host "Starting Azure Egress Validation Script..."
$startTime = Get-Date
$report = @()

# Get subscriptions to process
if (-not [string]::IsNullOrEmpty($SubscriptionId)) {
    $subscriptions = Get-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop
    if (-not $subscriptions) {
        Write-Error "Subscription with ID '$SubscriptionId' not found or not accessible."
        exit 1
    }
} else {
    $subscriptions = Get-AzSubscription | Where-Object {$_.State -eq "Enabled"}
    if (-not $subscriptions) {
        Write-Warning "No enabled subscriptions found or accessible."
        exit 1
    }
}

Write-Host "Found $($subscriptions.Count) subscription(s) to process."

# --- Main Processing Loop ---
foreach ($subscription in $subscriptions) {
    Write-Host "Processing Subscription: $($subscription.Name) ($($subscription.Id))"
    Set-AzContext -SubscriptionId $subscription.Id -ErrorAction Stop | Out-Null

    $resourceGroups = Get-AzResourceGroup
    Write-Host "Found $($resourceGroups.Count) resource groups in subscription '$($subscription.Name)'."

    foreach ($rg in $resourceGroups) {
        Write-Host "--- Scanning Resource Group: $($rg.ResourceGroupName) ---"

        # --- Process Virtual Machines ---
        $vms = Get-AzVM -ResourceGroupName $rg.ResourceGroupName
        if ($vms) {
            Write-Host "Found $($vms.Count) VMs in RG '$($rg.ResourceGroupName)'."
        }

        foreach ($vm in $vms) {
            Write-Verbose "Processing VM: $($vm.Name)"
            $vmNetworkInterfaces = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName | Where-Object { $_.VirtualMachine.Id -eq $vm.Id }

            foreach ($nic in $vmNetworkInterfaces) {
                Write-Verbose "  NIC: $($nic.Name)"
                foreach ($ipConfig in $nic.IpConfigurations) {
                    Write-Verbose "    IP Config: $($ipConfig.Name)"
                    $isDefaultEgress = $true # Assume default egress initially
                    $reason = "No explicit outbound method found yet."
                    $explicitMethodFoundForIpConfig = $false

                    if ($ipConfig.PublicIpAddress) {
                        $pip = Get-AzPublicIpAddress -ResourceId $ipConfig.PublicIpAddress.Id
                        if ($pip) {
                            if ($pip.Sku.Name -eq "Standard") {
                                $isDefaultEgress = $false
                                $reason = "VM NIC has a Standard Public IP: $($pip.Name)"
                                $explicitMethodFoundForIpConfig = $true
                            } elseif ($pip.Sku.Name -eq "Basic") {
                                $isDefaultEgress = $false
                                $reason = "VM NIC has a Basic Public IP: $($pip.Name). (Note: Standard SKU is recommended. This is an explicit method.)"
                                $explicitMethodFoundForIpConfig = $true
                            } else {
                                $reason = "VM NIC has a Public IP with unknown SKU: $($pip.Name) ($($pip.Sku.Name)). Further investigation needed."
                            }
                        } else {
                             $reason = "Public IP resource $($ipConfig.PublicIpAddress.Id) not found or inaccessible."
                        }
                    }

                    if (-not $explicitMethodFoundForIpConfig -and $ipConfig.LoadBalancerBackendAddressPools) {
                        foreach ($backendPool in $ipConfig.LoadBalancerBackendAddressPools) {
                            $lbIdParts = $backendPool.Id -split '/'
                            $lbRg = $lbIdParts[4]
                            $lbName = $lbIdParts[8]
                            
                            $lb = Get-AzLoadBalancer -ResourceGroupName $lbRg -Name $lbName
                            if ($lb) {
                                if ($lb.Sku.Name -eq "Standard" -and $lb.FrontendIPConfigurations.PublicIpAddress) {
                                    if ($lb.OutboundRules.Count -gt 0) {
                                        $isDefaultEgress = $false
                                        $reason = "VM NIC is in backend pool of Standard Public LB '$($lb.Name)' with outbound rules."
                                        $explicitMethodFoundForIpConfig = $true
                                        break 
                                    } else {
                                        $reason = "VM NIC is in backend pool of Standard Public LB '$($lb.Name)' but it has NO explicit outbound rules. This LB might rely on default SNAT (being retired) if DisableOutboundSnat is not true."
                                    }
                                } else {
                                     $reason = "VM NIC is in backend pool of LB '$($lb.Name)' which is not a Standard Public SKU or has no Public IP."
                                }
                            } else {
                                $reason = "Load Balancer for backend pool ID $($backendPool.Id) not found or inaccessible."
                            }
                            if ($explicitMethodFoundForIpConfig) { break }
                        }
                    }

                    if (-not $explicitMethodFoundForIpConfig) {
                        $subnetId = $ipConfig.Subnet.Id
                        $subnetObject = Get-AzVirtualNetworkSubnetConfig -ResourceId $subnetId
                        
                        if ($subnetObject) {
                            if ($subnetObject.NatGateway) {
                                $isDefaultEgress = $false
                                $reason = "Subnet '$($subnetObject.Name)' is configured with NAT Gateway: $($subnetObject.NatGateway.Id)"
                                $explicitMethodFoundForIpConfig = $true
                            }

                            if (-not $explicitMethodFoundForIpConfig -and $subnetObject.RouteTable) {
                                $routeTable = Get-AzRouteTable -ResourceId $subnetObject.RouteTable.Id
                                if ($routeTable) {
                                    $defaultRoute = $routeTable.Routes | Where-Object { $_.AddressPrefix -eq "0.0.0.0/0" }
                                    if ($defaultRoute) {
                                        if ($defaultRoute.NextHopType -eq "VirtualAppliance") {
                                            $isDefaultEgress = $false
                                            $reason = "Subnet '$($subnetObject.Name)' has UDR 0.0.0.0/0 to NVA: $($defaultRoute.NextHopIpAddress)"
                                            $explicitMethodFoundForIpConfig = $true
                                        } elseif ($defaultRoute.NextHopType -eq "Internet") {
                                            $isDefaultEgress = $true
                                            $reason = "Subnet '$($subnetObject.Name)' has UDR 0.0.0.0/0 directly to Internet. This will be impacted by default outbound retirement."
                                        } else {
                                            $isDefaultEgress = $true
                                            $reason = "Subnet '$($subnetObject.Name)' has UDR 0.0.0.0/0 to $($defaultRoute.NextHopType). Review needed; potentially relies on default outbound."
                                        }
                                    } else {
                                        $isDefaultEgress = $true
                                        $reason = "Subnet '$($subnetObject.Name)' has a UDR, but no 0.0.0.0/0 route. Uses system default to Internet."
                                    }
                                } else {
                                     $reason = "Route table $($subnetObject.RouteTable.Id) for subnet '$($subnetObject.Name)' not found or inaccessible."
                                }
                            } elseif (-not $explicitMethodFoundForIpConfig) {
                                $isDefaultEgress = $true
                                $reason = "Subnet '$($subnetObject.Name)' has no NAT Gateway and no UDR. Uses system default to Internet."
                            }
                        } else {
                             $reason = "Subnet with ID $($subnetId) for NIC '$($nic.Name)' not found or inaccessible."
                        }
                    }

                    if ($isDefaultEgress) {
                        $vmPowerState = "N/A (error retrieving)" # Default
                        try {
                            $vmStatus = Get-AzVM -ResourceId $vm.Id -Status -ErrorAction SilentlyContinue
                            if ($vmStatus -and $vmStatus.Statuses.Count -ge 2) {
                                $vmPowerState = $vmStatus.Statuses[1].DisplayStatus
                            } elseif ($vmStatus -and $vmStatus.Statuses.Count -eq 1) { # Handle cases where only one status element (e.g. provisioning state)
                                $vmPowerState = $vmStatus.Statuses[0].DisplayStatus
                            } elseif ($vm.ProvisioningState -eq 'Deallocated' -or $vm.ProvisioningState -eq 'Succeeded' -and ($vmStatus.PowerState -eq 'VM deallocated' -or !$vmStatus)) { # More explicit check for deallocated
                                $vmPowerState = "VM deallocated"
                            } else {
                                $vmPowerState = "N/A (status unavailable or unexpected)"
                            }
                        } catch {
                            $vmPowerState = "N/A (exception getting status)"
                        }

                        $reportItem = [PSCustomObject]@{
                            Timestamp           = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            SubscriptionName    = $subscription.Name
                            SubscriptionId      = $subscription.Id
                            ResourceGroupName   = $rg.ResourceGroupName
                            ResourceType        = "VM"
                            ResourceName        = $vm.Name
                            PowerState          = $vmPowerState
                            NIC                 = $nic.Name
                            IPConfiguration     = $ipConfig.Name
                            PrivateIPAddress    = $ipConfig.PrivateIpAddress
                            SubnetName          = ($ipConfig.Subnet.Id -split '/')[-1]
                            VirtualNetwork      = ($ipConfig.Subnet.Id -split '/')[-3]
                            IsLikelyDefaultEgress = $isDefaultEgress
                            Reason              = $reason
                        }
                        $report += $reportItem
                        Write-Warning "VM '$($vm.Name)' (NIC '$($nic.Name)', IPConfig '$($ipConfig.Name)') in RG '$($rg.ResourceGroupName)' is potentially using default outbound access. Reason: $reason"
                    } else {
                         Write-Verbose "VM '$($vm.Name)' (NIC '$($nic.Name)', IPConfig '$($ipConfig.Name)') has explicit outbound. Reason: $reason"
                    }
                } 
            } 
        } 

        $vmsses = Get-AzVmss -ResourceGroupName $rg.ResourceGroupName
        if ($vmsses) {
            Write-Host "Found $($vmsses.Count) VM Scale Sets in RG '$($rg.ResourceGroupName)'."
        }
        foreach ($vmss in $vmsses) {
            Write-Verbose "Processing VMSS: $($vmss.Name)"
            $vmssInstances = Get-AzVmssVM -ResourceGroupName $vmss.ResourceGroupName -VMScaleSetName $vmss.Name 

            foreach ($instance in $vmssInstances) {
                Write-Verbose "  VMSS Instance: $($instance.Name)"
                $instanceView = Get-AzVmssVM -ResourceGroupName $vmss.ResourceGroupName -VMScaleSetName $vmss.Name -InstanceId $instance.InstanceId -InstanceView
                $instanceNics = $null
                if($instanceView.NetworkProfile){ # Check if NetworkProfile exists
                    $instanceNics = $instanceView.NetworkProfile.NetworkInterfaces
                } else {
                    Write-Warning "NetworkProfile not found for VMSS instance $($instance.Name) in VMSS $($vmss.Name). Skipping NIC checks for this instance."
                    Continue # Skip to next instance if no network profile
                }


                foreach ($nicRef in $instanceNics) { 
                    $nic = Get-AzNetworkInterface -ResourceId $nicRef.Id
                    if (-not $nic) { Write-Warning "Could not retrieve NIC with ID $($nicRef.Id) for VMSS instance $($instance.Name). Skipping."; continue }

                    Write-Verbose "    NIC: $($nic.Name)"
                    foreach ($ipConfig in $nic.IpConfigurations) {
                        Write-Verbose "      IP Config: $($ipConfig.Name)"
                        $isDefaultEgress = $true 
                        $reason = "No explicit outbound method found yet for VMSS instance."
                        $explicitMethodFoundForIpConfig = $false

                        if ($ipConfig.PublicIpAddress) {
                             $pip = Get-AzPublicIpAddress -ResourceId $ipConfig.PublicIpAddress.Id
                             if ($pip) {
                                if ($pip.Sku.Name -eq "Standard") {
                                    $isDefaultEgress = $false
                                    $reason = "VMSS instance '$($instance.Name)' NIC has a Standard Public IP: $($pip.Name)"
                                    $explicitMethodFoundForIpConfig = $true
                                } elseif ($pip.Sku.Name -eq "Basic") {
                                    $isDefaultEgress = $false
                                    $reason = "VMSS instance '$($instance.Name)' NIC has a Basic Public IP: $($pip.Name). (Note: Standard SKU is recommended. This is an explicit method.)"
                                    $explicitMethodFoundForIpConfig = $true
                                } else {
                                    $reason = "VMSS instance '$($instance.Name)' NIC has a Public IP with unknown SKU: $($pip.Name) ($($pip.Sku.Name))."
                                }
                             } else {
                                $reason = "Public IP resource $($ipConfig.PublicIpAddress.Id) for VMSS instance not found."
                             }
                        }

                        if (-not $explicitMethodFoundForIpConfig -and $ipConfig.LoadBalancerBackendAddressPools) {
                            foreach ($backendPool in $ipConfig.LoadBalancerBackendAddressPools) {
                                $lbIdParts = $backendPool.Id -split '/'
                                $lbRg = $lbIdParts[4]
                                $lbName = $lbIdParts[8]
                                
                                $lb = Get-AzLoadBalancer -ResourceGroupName $lbRg -Name $lbName
                                if ($lb) {
                                    if ($lb.Sku.Name -eq "Standard" -and $lb.FrontendIPConfigurations.PublicIpAddress) {
                                        if ($lb.OutboundRules.Count -gt 0) {
                                            $isDefaultEgress = $false
                                            $reason = "VMSS instance '$($instance.Name)' NIC is in backend pool of Standard Public LB '$($lb.Name)' with outbound rules."
                                            $explicitMethodFoundForIpConfig = $true
                                            break 
                                        } else {
                                            $reason = "VMSS instance '$($instance.Name)' NIC is in backend pool of Standard Public LB '$($lb.Name)' but it has NO explicit outbound rules. This LB might rely on default SNAT if DisableOutboundSnat is not true."
                                        }
                                    } else {
                                        $reason = "VMSS instance '$($instance.Name)' NIC is in backend pool of LB '$($lb.Name)' which is not a Standard Public SKU or has no Public IP."
                                    }
                                } else {
                                     $reason = "Load Balancer for backend pool ID $($backendPool.Id) for VMSS instance not found."
                                }
                                if ($explicitMethodFoundForIpConfig) { break }
                            }
                        }
                        
                        if (-not $explicitMethodFoundForIpConfig) {
                            $subnetId = $ipConfig.Subnet.Id
                            $subnetObject = Get-AzVirtualNetworkSubnetConfig -ResourceId $subnetId
                            
                            if ($subnetObject) {
                                if ($subnetObject.NatGateway) {
                                    $isDefaultEgress = $false
                                    $reason = "VMSS instance '$($instance.Name)' in Subnet '$($subnetObject.Name)' configured with NAT Gateway: $($subnetObject.NatGateway.Id)"
                                    $explicitMethodFoundForIpConfig = $true
                                }

                                if (-not $explicitMethodFoundForIpConfig -and $subnetObject.RouteTable) {
                                    $routeTable = Get-AzRouteTable -ResourceId $subnetObject.RouteTable.Id
                                    if ($routeTable) {
                                        $defaultRoute = $routeTable.Routes | Where-Object { $_.AddressPrefix -eq "0.0.0.0/0" }
                                        if ($defaultRoute) {
                                            if ($defaultRoute.NextHopType -eq "VirtualAppliance") {
                                                $isDefaultEgress = $false
                                                $reason = "VMSS instance '$($instance.Name)' in Subnet '$($subnetObject.Name)' has UDR 0.0.0.0/0 to NVA: $($defaultRoute.NextHopIpAddress)"
                                                $explicitMethodFoundForIpConfig = $true
                                            } elseif ($defaultRoute.NextHopType -eq "Internet") {
                                                $isDefaultEgress = $true
                                                $reason = "VMSS instance '$($instance.Name)' in Subnet '$($subnetObject.Name)' has UDR 0.0.0.0/0 directly to Internet. This will be impacted."
                                            } else {
                                                $isDefaultEgress = $true
                                                $reason = "VMSS instance '$($instance.Name)' in Subnet '$($subnetObject.Name)' has UDR 0.0.0.0/0 to $($defaultRoute.NextHopType). Review needed."
                                            }
                                        } else {
                                            $isDefaultEgress = $true
                                            $reason = "VMSS instance '$($instance.Name)' in Subnet '$($subnetObject.Name)' has a UDR, but no 0.0.0.0/0 route. Uses system default."
                                        }
                                    } else {
                                        $reason = "Route table $($subnetObject.RouteTable.Id) for VMSS subnet '$($subnetObject.Name)' not found."
                                    }
                                } elseif (-not $explicitMethodFoundForIpConfig) {
                                    $isDefaultEgress = $true
                                    $reason = "VMSS instance '$($instance.Name)' in Subnet '$($subnetObject.Name)' has no NAT Gateway and no UDR. Uses system default."
                                }
                            } else {
                                 $reason = "Subnet with ID $($subnetId) for VMSS instance NIC '$($nic.Name)' not found."
                            }
                        }

                        if ($isDefaultEgress) {
                            $instancePowerState = "N/A (error retrieving)"
                            try {
                                if ($instanceView -and $instanceView.Statuses.Count -ge 2) {
                                    $instancePowerState = $instanceView.Statuses[1].DisplayStatus
                                } elseif ($instanceView -and $instanceView.Statuses.Count -eq 1) {
                                     $instancePowerState = $instanceView.Statuses[0].DisplayStatus
                                } elseif ($instance.ProvisioningState -eq 'Deallocated' -or $instance.ProvisioningState -eq 'Succeeded' -and ($instanceView.PowerState -eq 'VM deallocated' -or !$instanceView) ) {
                                     $instancePowerState = "VM deallocated"
                                } else {
                                    $instancePowerState = "N/A (status unavailable or unexpected)"
                                }
                            } catch {
                                $instancePowerState = "N/A (exception getting status)"
                            }

                            $reportItem = [PSCustomObject]@{
                                Timestamp           = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                                SubscriptionName    = $subscription.Name
                                SubscriptionId      = $subscription.Id
                                ResourceGroupName   = $rg.ResourceGroupName
                                ResourceType        = "VMSS Instance"
                                ResourceName        = "$($vmss.Name)/$($instance.Name)"
                                PowerState          = $instancePowerState
                                NIC                 = $nic.Name
                                IPConfiguration     = $ipConfig.Name
                                PrivateIPAddress    = $ipConfig.PrivateIpAddress
                                SubnetName          = ($ipConfig.Subnet.Id -split '/')[-1]
                                VirtualNetwork      = ($ipConfig.Subnet.Id -split '/')[-3]
                                IsLikelyDefaultEgress = $isDefaultEgress
                                Reason              = $reason
                            }
                            $report += $reportItem
                            Write-Warning "VMSS Instance '$($instance.Name)' in VMSS '$($vmss.Name)' (NIC '$($nic.Name)', IPConfig '$($ipConfig.Name)') in RG '$($rg.ResourceGroupName)' is potentially using default outbound access. Reason: $reason"
                        } else {
                            Write-Verbose "VMSS Instance '$($instance.Name)' (NIC '$($nic.Name)', IPConfig '$($ipConfig.Name)') has explicit outbound. Reason: $reason"
                        }
                    } 
                } 
            } 
        } 
    } 
} 

# --- Reporting ---
Write-Host "`n--- Script Execution Summary ---"
$endTime = Get-Date
Write-Host "Script started at: $startTime"
Write-Host "Script finished at: $endTime"
Write-Host "Total duration: $($endTime - $startTime)"

if ($report.Count -gt 0) {
    Write-Warning "$($report.Count) resources identified as potentially using default outbound access."
    Write-Host "Review the following flagged resources:"
    $report | Format-Table -AutoSize

    if (-not [string]::IsNullOrEmpty($CsvExportPath)) {
        try {
            $report | Export-Csv -Path $CsvExportPath -NoTypeInformation -Encoding UTF8
            Write-Host "`nReport successfully exported to: $CsvExportPath"
        } catch {
            Write-Error "Failed to export report to CSV: $($_.Exception.Message)"
        }
    } else {
        Write-Host "`nTo export this report to CSV, re-run the script with the -CsvExportPath parameter."
    }
} else {
    Write-Host "No resources identified as potentially using default outbound access based on the checks performed."
}

Write-Host "--- Azure Egress Validation Script Finished ---"