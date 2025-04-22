# Script to identify Generation V2 VMs across all Azure subscriptions
# Generation V2 VMs typically have these security features:
# - secureBootEnabled: true/false (only available on Gen2)
# - virtualTpmEnabled: true/false (only available on Gen2)
# - encryptionAtHost: true/false
# - securityType: TrustedLaunch, ConfidentialVM (requires Gen2)

# Connect to Azure Account
try {
    Write-Host "Connecting to Azure..." -ForegroundColor Cyan
    Connect-AzAccount -ErrorAction Stop
    Write-Host "Successfully connected to Azure" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Azure: $_"
    exit 1
}

# Initialize result collection
$VM_V2 = @()
$subscriptionCount = 0
$totalVMCount = 0
$totalV2VMCount = 0

# Get all subscriptions
$subscriptions = Get-AzSubscription
Write-Host "Found $($subscriptions.Count) subscriptions to scan" -ForegroundColor Yellow

foreach ($subscription in $subscriptions) {
    $subscriptionCount++
    try {
        # Set context to current subscription
        Write-Host "[$subscriptionCount/$($subscriptions.Count)] Processing subscription: $($subscription.Name) ($($subscription.Id))" -ForegroundColor Cyan
        Set-AzContext -SubscriptionId $subscription.Id -ErrorAction Stop | Out-Null
        
        # Get all VMs in the subscription
        $vms = Get-AzVM
        $subVMCount = $vms.Count
        $totalVMCount += $subVMCount
        Write-Host "  Found $subVMCount VMs in this subscription" -ForegroundColor Gray
        
        # Filter for Gen2 VMs
        $v2VMs = $vms | Where-Object { 
            # Check if VM is Generation V2 by looking at security features
            $_.SecurityProfile -ne $null -and 
            ($_.SecurityProfile.SecureBootEnabled -eq $true -or 
             $_.SecurityProfile.VirtualTPMEnabled -eq $true -or
             $_.SecurityProfile.SecurityType -eq "TrustedLaunch" -or
             $_.SecurityProfile.SecurityType -eq "ConfidentialVM")
        }
          # If we found any Gen2 VMs, add them to our results
        if ($v2VMs) {
            $v2VMCount = $v2VMs.Count
            $totalV2VMCount += $v2VMCount
            Write-Host "  Found $v2VMCount Generation V2 VMs in this subscription" -ForegroundColor Green
            $VM_V2 += $v2VMs | Select-Object @{Name="SubscriptionName"; Expression={$subscription.Name}}, 
                                            @{Name="SubscriptionId"; Expression={$subscription.Id}}, 
                                            ResourceGroupName, 
                                            Name, 
                                            Location,
                                            @{Name="VMSize"; Expression={$_.HardwareProfile.VmSize}},
                                            @{Name="SecureBoot"; Expression={
                                                if ($null -ne $_.SecurityProfile.SecureBootEnabled) { 
                                                    $_.SecurityProfile.SecureBootEnabled 
                                                } else { 
                                                    "Not Set" 
                                                }
                                            }},
                                            @{Name="VirtualTPM"; Expression={
                                                if ($null -ne $_.SecurityProfile.VirtualTPMEnabled) { 
                                                    $_.SecurityProfile.VirtualTPMEnabled 
                                                } else { 
                                                    "Not Set" 
                                                }
                                            }},
                                            @{Name="SecurityType"; Expression={
                                                if ($null -ne $_.SecurityProfile.SecurityType) { 
                                                    $_.SecurityProfile.SecurityType 
                                                } else { 
                                                    "Not Set" 
                                                }
                                            }},
                                            @{Name="EncryptionAtHost"; Expression={
                                                if ($null -ne $_.SecurityProfile.EncryptionAtHost) { 
                                                    $_.SecurityProfile.EncryptionAtHost 
                                                } else { 
                                                    "Not Set" 
                                                }
                                            }}
        }
    }
    catch {
        Write-Warning "Error processing subscription $($subscription.Name): $_"
    }
}

# Display summary
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Processed $subscriptionCount subscriptions" -ForegroundColor White
Write-Host "Found $totalVMCount total VMs" -ForegroundColor White
Write-Host "Found $totalV2VMCount Generation V2 VMs" -ForegroundColor Green

# Output results
if ($VM_V2.Count -gt 0) {
    Write-Host "`nGeneration V2 VMs:" -ForegroundColor Yellow
    $VM_V2 | Format-Table -AutoSize
      # Ask if the user wants to export to CSV
    $exportCSV = Read-Host "Do you want to export the results to CSV? (Y/N)"
    if ($exportCSV -eq "Y" -or $exportCSV -eq "y") {
        $exportPath = "C:\temp\VM_Gen2_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        
        # Ensure the C:\temp directory exists
        if (!(Test-Path "C:\temp")) {
            New-Item -ItemType Directory -Path "C:\temp" -Force | Out-Null
            Write-Host "Created directory: C:\temp" -ForegroundColor Yellow
        }
        
        $VM_V2 | Export-Csv -Path $exportPath -NoTypeInformation
        Write-Host "Results exported to: $exportPath" -ForegroundColor Green
    }
}
else {
    Write-Host "No Generation V2 VMs found across all subscriptions." -ForegroundColor Yellow
}