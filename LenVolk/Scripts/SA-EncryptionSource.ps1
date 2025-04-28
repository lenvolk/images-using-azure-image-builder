# Storage Account Encryption Report
# This script identifies all storage accounts across all subscriptions and reports their encryption settings
# It distinguishes between Microsoft-managed keys and customer-managed keys

# Storage Account Encryption Report Script
# Key Features:
# Authentication Handling:

# Connects to Azure automatically (with option to skip using -SkipLogin parameter)
# Handles authentication errors gracefully
# Comprehensive Data Collection:

# Scans all your Azure subscriptions
# Identifies every storage account in each subscription
# Extracts detailed encryption settings
# Detailed Encryption Information:

# Classifies each storage account as using either:
# Microsoft-managed keys (MMK)
# Customer-managed keys (CMK)
# Captures encryption details for all storage services (Blobs, Files, Tables, Queues)
# For customer-managed keys, reports Key Vault name, key name, version, and last rotation time
# Includes information about infrastructure encryption (double encryption)
# Additional Security Details:

# Captures HTTPS-only settings
# Reports public blob access settings
# Documents minimum TLS version
# Rich Reporting:

# Outputs console summary with color-coded information
# Generates detailed CSV report to C:\temp (with timestamp in filename)
# Displays encryption summary by subscription
# Shows percentage of storage accounts using CMK by subscription
# User-Friendly Features:

# Progress indicators during execution
# Creation of output directory if it doesn't exist
# Option to open the CSV report after generation
# Detailed error handling

# Specify custom output path
# .\SA-EncryptionSource.ps1 -OutputPath "C:\Reports\StorageAccountReport.csv"


# Script parameters
param (
    [switch]$SkipLogin,
    [string]$OutputPath = "C:\temp\StorageAccount_EncryptionReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

# Function to ensure directory exists
function Ensure-DirectoryExists {
    param (
        [string]$DirectoryPath
    )
    
    if (!(Test-Path $DirectoryPath)) {
        New-Item -ItemType Directory -Path $DirectoryPath -Force | Out-Null
        Write-Host "Created directory: $DirectoryPath" -ForegroundColor Yellow
    }
}

# Function to format encryption settings for display
function Format-EncryptionSettings {
    param (
        [object]$StorageAccount
    )
    
    $encryptionSettings = @{
        "BlobEncryption" = "N/A"
        "FileEncryption" = "N/A"
        "TableEncryption" = "N/A"
        "QueueEncryption" = "N/A"
        "EncryptionKeySource" = "N/A"
        "KeyVaultName" = "N/A"
        "KeyName" = "N/A"
        "KeyVersion" = "N/A"
        "LastKeyRotation" = "N/A"
        "MicrosoftManagedKeyInfrastructureEncryption" = "N/A"
    }
    
    # Check encryption settings
    if ($StorageAccount.Encryption -ne $null) {
        # Service encryption status
        if ($StorageAccount.Encryption.Services -ne $null) {
            if ($StorageAccount.Encryption.Services.Blob -ne $null) {
                $encryptionSettings["BlobEncryption"] = $StorageAccount.Encryption.Services.Blob.Enabled
            }
            if ($StorageAccount.Encryption.Services.File -ne $null) {
                $encryptionSettings["FileEncryption"] = $StorageAccount.Encryption.Services.File.Enabled
            }
            if ($StorageAccount.Encryption.Services.Table -ne $null) {
                $encryptionSettings["TableEncryption"] = $StorageAccount.Encryption.Services.Table.Enabled
            }
            if ($StorageAccount.Encryption.Services.Queue -ne $null) {
                $encryptionSettings["QueueEncryption"] = $StorageAccount.Encryption.Services.Queue.Enabled
            }
        }
        
        # Key source (Microsoft-managed or Customer-managed)
        if ($StorageAccount.Encryption.KeySource -ne $null) {
            $encryptionSettings["EncryptionKeySource"] = $StorageAccount.Encryption.KeySource
        }
        
        # Customer-managed key details (if applicable)
        if ($StorageAccount.Encryption.KeySource -eq "Microsoft.Keyvault") {
            if ($StorageAccount.Encryption.KeyVaultProperties -ne $null) {
                $encryptionSettings["KeyVaultName"] = $StorageAccount.Encryption.KeyVaultProperties.KeyVaultUri -replace "https://", "" -replace "\.vault\.azure\.net/.*", ""
                $encryptionSettings["KeyName"] = $StorageAccount.Encryption.KeyVaultProperties.KeyName
                $encryptionSettings["KeyVersion"] = $StorageAccount.Encryption.KeyVaultProperties.KeyVersion
                $encryptionSettings["LastKeyRotation"] = $StorageAccount.Encryption.KeyVaultProperties.LastKeyRotationTimestamp
            }
        }
        
        # Infrastructure encryption (double encryption)
        if ($StorageAccount.Encryption.RequireInfrastructureEncryption -ne $null) {
            $encryptionSettings["MicrosoftManagedKeyInfrastructureEncryption"] = $StorageAccount.Encryption.RequireInfrastructureEncryption
        }
    }
    
    return $encryptionSettings
}

# Connect to Azure Account (if not skipped)
if (-not $SkipLogin) {
    try {
        Write-Host "Connecting to Azure..." -ForegroundColor Cyan
        Connect-AzAccount -ErrorAction Stop
        Write-Host "Successfully connected to Azure" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to connect to Azure: $_"
        exit 1
    }
}

# Initialize result collection
$storageAccountsReport = @()
$subscriptionCount = 0
$storageAccountCount = 0
$mmkCount = 0
$cmkCount = 0

# Ensure output directory exists
Ensure-DirectoryExists -DirectoryPath (Split-Path -Parent $OutputPath)

# Get all subscriptions
$subscriptions = Get-AzSubscription
Write-Host "Found $($subscriptions.Count) subscriptions to scan" -ForegroundColor Yellow

foreach ($subscription in $subscriptions) {
    $subscriptionCount++
    try {
        # Set context to current subscription
        Write-Host "[$subscriptionCount/$($subscriptions.Count)] Processing subscription: $($subscription.Name) ($($subscription.Id))" -ForegroundColor Cyan
        Set-AzContext -SubscriptionId $subscription.Id -ErrorAction Stop | Out-Null
        
        # Get all storage accounts in the subscription
        $storageAccounts = Get-AzStorageAccount -ErrorAction SilentlyContinue
        $subSACount = $storageAccounts.Count
        $storageAccountCount += $subSACount
        Write-Host "  Found $subSACount storage accounts in this subscription" -ForegroundColor Gray
        
        # Process each storage account
        foreach ($sa in $storageAccounts) {
            # Get encryption settings
            $encryptionSettings = Format-EncryptionSettings -StorageAccount $sa
            
            # Count by key type
            if ($encryptionSettings["EncryptionKeySource"] -eq "Microsoft.Keyvault") {
                $cmkCount++
                $keyType = "Customer-managed key (CMK)"
            } else {
                $mmkCount++
                $keyType = "Microsoft-managed key (MMK)"
            }
            
            # Add to report
            $storageAccountsReport += [PSCustomObject]@{
                "SubscriptionName" = $subscription.Name
                "SubscriptionId" = $subscription.Id
                "ResourceGroupName" = $sa.ResourceGroupName
                "StorageAccountName" = $sa.StorageAccountName
                "Location" = $sa.Location
                "Kind" = $sa.Kind
                "SKU" = $sa.Sku.Name
                "AccessTier" = $sa.AccessTier
                "EncryptionKeyType" = $keyType
                "EncryptionKeySource" = $encryptionSettings["EncryptionKeySource"]
                "BlobEncryption" = $encryptionSettings["BlobEncryption"]
                "FileEncryption" = $encryptionSettings["FileEncryption"]
                "TableEncryption" = $encryptionSettings["TableEncryption"]
                "QueueEncryption" = $encryptionSettings["QueueEncryption"]
                "KeyVaultName" = $encryptionSettings["KeyVaultName"]
                "KeyName" = $encryptionSettings["KeyName"]
                "KeyVersion" = $encryptionSettings["KeyVersion"]
                "LastKeyRotation" = $encryptionSettings["LastKeyRotation"]
                "InfrastructureEncryption" = $encryptionSettings["MicrosoftManagedKeyInfrastructureEncryption"]
                "CreationTime" = $sa.CreationTime
                "EnableHttpsTrafficOnly" = $sa.EnableHttpsTrafficOnly
                "AllowBlobPublicAccess" = $sa.AllowBlobPublicAccess
                "MinimumTlsVersion" = $sa.MinimumTlsVersion
            }
            
            Write-Host "    Processed: $($sa.StorageAccountName) - $keyType" -ForegroundColor Gray
        }
    }
    catch {
        Write-Warning "Error processing subscription $($subscription.Name): $_"
    }
}

# Display summary
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Processed $subscriptionCount subscriptions" -ForegroundColor White
Write-Host "Found $storageAccountCount total Storage Accounts" -ForegroundColor White
Write-Host "  Microsoft-managed keys (MMK): $mmkCount" -ForegroundColor Yellow
Write-Host "  Customer-managed keys (CMK): $cmkCount" -ForegroundColor Green

# Display detailed results and export
if ($storageAccountsReport.Count -gt 0) {
    Write-Host "`nStorage Account Encryption Report:" -ForegroundColor Yellow
    $storageAccountsReport | 
        Select-Object StorageAccountName, ResourceGroupName, SubscriptionName, Location, EncryptionKeyType, EncryptionKeySource, KeyVaultName |
        Format-Table -AutoSize
    
    # Export to CSV
    $storageAccountsReport | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "Full report exported to: $OutputPath" -ForegroundColor Green
    
    # Generate summary by subscription
    Write-Host "`nEncryption Summary by Subscription:" -ForegroundColor Yellow
    $subscriptionSummary = $storageAccountsReport | 
        Group-Object -Property SubscriptionName | 
        ForEach-Object {
            $mmkInSub = ($_.Group | Where-Object { $_.EncryptionKeyType -like "*Microsoft*" }).Count
            $cmkInSub = ($_.Group | Where-Object { $_.EncryptionKeyType -like "*Customer*" }).Count
            
            [PSCustomObject]@{
                "SubscriptionName" = $_.Name
                "TotalStorageAccounts" = $_.Count
                "Microsoft-managed keys" = $mmkInSub
                "Customer-managed keys" = $cmkInSub
                "CMK %" = if ($_.Count -gt 0) { [math]::Round(($cmkInSub / $_.Count) * 100, 1) } else { 0 }
            }
        }
    
    $subscriptionSummary | Format-Table -AutoSize
    
    # Ask if user wants to open the CSV
    $openCSV = Read-Host "Do you want to open the CSV report? (Y/N)"
    if ($openCSV -eq "Y" -or $openCSV -eq "y") {
        Invoke-Item $OutputPath
    }
}
else {
    Write-Host "No storage accounts found across all subscriptions." -ForegroundColor Yellow
}
