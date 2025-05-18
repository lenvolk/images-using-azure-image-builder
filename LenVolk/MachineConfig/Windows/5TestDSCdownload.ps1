# Ensure the Az.Accounts and Az.Storage modules are installed
# Install-Module Az.Accounts -Scope CurrentUser -Force
# Install-Module Az.Storage -Scope CurrentUser -Force

# Assume $ManagedIdentityResourceId is already populated from your previous steps.
# For example:
# $ManagedIdentityResourceId = "/subscriptions/c29da00a-953c-4188-894e-70657319863a/resourceGroups/Bastion/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ToolsMSI"

# --- Parameters ---
$blobUrl = "https://sharexvolkbike.blob.core.windows.net/machine-configuration/TimeZone.zip"
# Define where you want to save the downloaded file
$destinationFilePath = ".\TimeZone.zip" # Downloads to the current script directory
# --- End of Parameters ---

# Verbose output for Managed Identity being used
Write-Host "Attempting to use Managed Identity with Resource ID: $ManagedIdentityResourceId"

# 1. Connect to Azure using the User-Assigned Managed Identity
# This command needs to be run in an environment where the Managed Identity can be assumed,
# such as an Azure VM with the identity assigned, Azure Cloud Shell, or an environment
# with appropriate workload identity federation configured.
try {
    Connect-AzAccount -Identity -AccountId $ManagedIdentityResourceId -ErrorAction Stop
    Write-Host "Successfully connected to Azure using the Managed Identity."
}
catch {
    Write-Error "Failed to connect using Managed Identity. Ensure the script is run in an Azure environment (e.g., VM, Function, Cloud Shell) with the Managed Identity assigned and appropriate permissions, or that the identity is correctly federated."
    Write-Error "Error details: $($_.Exception.Message)"
    exit 1 # Exit if connection fails
}

# 2. Parse the Blob URL to get components
try {
    $uri = [System.Uri]$blobUrl
    $storageAccountName = $uri.Host.Split('.')[0]
    $pathParts = $uri.AbsolutePath.Trim('/').Split('/')
    $containerName = $pathParts[0]
    $blobName = ($pathParts | Select-Object -Skip 1) -join '/' # Handles blobs in 'virtual folders'

    Write-Host "Storage Account: $storageAccountName"
    Write-Host "Container: $containerName"
    Write-Host "Blob Name: $blobName"
    Write-Host "Destination: $destinationFilePath"
}
catch {
    Write-Error "Failed to parse the blob URL: $blobUrl"
    Write-Error "Error details: $($_.Exception.Message)"
    exit 1
}


# Ensure the destination directory exists (if $destinationFilePath includes a path)
$destinationDirectory = Split-Path -Path $destinationFilePath -Parent
if ($destinationDirectory -and (-not (Test-Path -Path $destinationDirectory))) {
    Write-Host "Creating destination directory: $destinationDirectory"
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
}

# 3. Download the blob using the Managed Identity context
try {
    Write-Host "Attempting to download '$blobName' from container '$containerName' in storage account '$storageAccountName'..."
    Get-AzStorageBlobContent -AccountName $storageAccountName -Container $containerName -Blob $blobName -Destination $destinationFilePath -Force -ErrorAction Stop
    Write-Host "Blob successfully downloaded to: $((Resolve-Path $destinationFilePath).Path)"
}
catch {
    Write-Error "Failed to download blob."
    Write-Error "Error details: $($_.Exception.Message)"
    Write-Error "Please ensure the Managed Identity '$ManagedIdentityResourceId' has the 'Storage Blob Data Reader' (or equivalent) role on the storage account '$storageAccountName' or the specific container/blob."
    exit 1
}

# Optional: If you need to switch back to a different account context after this script.
# For a standalone script, this is often not necessary.
# Clear-AzContext -Scope Process -Force