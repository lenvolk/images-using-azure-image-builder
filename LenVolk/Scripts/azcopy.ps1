#######################################
#              AzCopy                  #
#######################################
# download azcopy https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10#download-azcopy

# Define the path to the AzCopy directory
$azCopyPath = "C:\AzCopy"

# Check if the AzCopy directory exists, create it if it doesn't
if (-not (Test-Path -Path $azCopyPath)) {
    New-Item -Path $azCopyPath -ItemType Directory
    Write-Output "Created directory: $azCopyPath"
} else {
    Write-Output "Directory already exists: $azCopyPath"
}

# Define the URL to download AzCopy
$azCopyUrl = "https://aka.ms/downloadazcopy-v10-windows"

# Define the path to save the downloaded AzCopy zip file
$azCopyZipPath = "$azCopyPath\azcopy.zip"

# Download AzCopy
Invoke-WebRequest -Uri $azCopyUrl -OutFile $azCopyZipPath
Write-Output "Downloaded AzCopy to: $azCopyZipPath"

# Extract the AzCopy zip file
Expand-Archive -Path $azCopyZipPath -DestinationPath $azCopyPath
Write-Output "Extracted AzCopy to: $azCopyPath"

# Clean up the downloaded zip file
Remove-Item -Path $azCopyZipPath
Write-Output "Removed the downloaded zip file: $azCopyZipPath"

# Add AzCopy to the PATH environment variable
$envPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
if ($envPath -notlike "*$azCopyPath*") {
    $newPath = "$envPath;$azCopyPath"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
    Write-Output "AzCopy path added to the PATH environment variable."
} else {
    Write-Output "AzCopy path is already in the PATH environment variable."
}

# Verify the setup
$updatedPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
if ($updatedPath -like "*$azCopyPath*") {
    Write-Output "AzCopy path successfully added to the PATH environment variable."
} else {
    Write-Output "Failed to add AzCopy path to the PATH environment variable."
}

############################################################################################################################################################################
############################################################################################################################################################################
############################################################################################################################################################################

# azcopy with MSI
# SA IAM: Storage Blob Data Reader OR Storage Blob Data Owner + Storage Account Contributor to VM's Identity   
# az role assignment create --assignee <managed-identity-id> --role "Storage Blob Data Contributor" --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>
# az role assignment create --assignee <managed-identity-id> --role "Reader" --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>
# (might need to add role Storage Blob Data Reader to RG where SA is for arc MSI
# Add your login account to the SA with Storage Blob Data Reader )

# test connectivities to the storage account
nslookup volkarchive.blob.core.windows.net

.\azcopy.exe login --identity

.\azcopy.exe make 'https://volkarchive.blob.core.windows.net/sharepoint'
.\azcopy.exe list 'https://volkarchive.blob.core.windows.net/sharepoint'

# TEST via benchmark
.\azcopy.exe benchmark 'https://volkarchive.blob.core.windows.net/sharepoint'

.\azcopy.exe sync "C:\Temp\sharepoint" "https://volkarchive.blob.core.windows.net/sharepoint" --recursive


# review the log file 
# Define the path to the log file
$logFilePath = "C:\Users\lv\.azcopy\b4bad7bd-e6f6-6d46-7b19-f81e7a1d9951.log"
# Open the log file with Notepad
Start-Process "notepad.exe" -ArgumentList $logFilePath


.\azcopy.exe logout

############################################################################################################################################################################
############################################################################################################################################################################
############################################################################################################################################################################




# az account clear
# az login --identity

# az storage account show -n fileservervolk --query networkRuleSet

# # create test file
# fsutil file createnew testfile.txt 104857600

# #upload single file

# $start = Get-Date
# az storage blob upload --account-name volkarchive --container-name sharepoint --name testfile.txt --file C:\Temp\sharepoint\testfile.txt --auth-mode login
# $end = Get-Date
# $duration = $end - $start

# $fileSizeMB = 100 # Size of the file in MB
# $uploadSpeedMbps = ($fileSizeMB * 8) / $duration.TotalSeconds
# Write-Output "Upload Speed: $uploadSpeedMbps Mbps"

# #upload folder
# az storage blob upload-batch --account-name fileservervolk --destination sharepoint --source C:\temp --overwrite --auth-mode login


# ###################
# # azcopy
# # .\azcopy -h
# .\azcopy logout
# .\azcopy login --identity

# $start = Get-Date
# .\azcopy sync "C:\Temp\sharepoint" "https://volkarchive.blob.core.windows.net/sharepoint"
# $end = Get-Date
# $duration = $end - $start

# $fileSizeMB = 100 # Size of the file in MB
# $uploadSpeedMbps = ($fileSizeMB * 8) / $duration.TotalSeconds
# Write-Output "Upload Speed: $uploadSpeedMbps Mbps"


# # sync folder
# .\azcopy sync "C:\Temp\sharepoint" "https://fileservervolk.blob.core.windows.net/sharepoint"


# az storage blob list --account-name fileservervolk --container-name sharepoint --output table --auth-mode login