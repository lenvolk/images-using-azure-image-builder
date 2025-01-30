# Author: Paul Dunne (Microsoft)
# Created: 2025-01-28
# Last Modified: 2025-01-29
# Version: 2.0

# Description: This script connects to an Azure Storage Account and retrieves size usage about all provisioned Azure Files shares, folders and files.
#              It uses Azure AD authentication and the Az.Storage and Az.Resources modules.
#
#              It can be used in scenarios where you need to get an overview of the size of all folders, subfolders and files in Azure Files shares.
#              It may be useful for cross-charging, where a customer has provisioned a single file share which is utilised by multiple cost centres in the business
#
#              The script exports the information to a CSV file named "AzureFiles-Consumption.csv" in the current directory.

# Disclaimer: This script is provided "as is" without warranty of any kind, either express or implied, including but not limited to the implied warranties of merchantability and/or fitness for a particular purpose.

# Parameters:
#   - sourceTentantId: The Tenant ID of the Azure AD directory.
#   - sourceAzureSubscriptionId: The Subscription ID of the Azure subscription.
#   - sourceStorageAccountName: The name of the Azure Storage Account.

# RBAC Requirements:
#   - Reader role on the Azure subscription to read storage account information.
#   - Storage File Data Privileged Contributor role on the storage account to list and read file shares, folders, and files.


# Usage: . .\AzureFiles-Consumption.ps1 -sourceTentantId <TenantId> -sourceAzureSubscriptionId <SubscriptionId> -sourceStorageAccountName <StorageAccountName>

# Set Mandatory Parameters
[CmdletBinding(SupportsShouldProcess = $true)]
Param (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $sourceTentantId,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $sourceAzureSubscriptionId,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $sourceStorageAccountName
)

# Install the required Az modules
Install-Module -Name Az.Storage -AllowClobber
Install-Module Az.Resources -AllowClobber

# Prevent the inheritance of an AzContext from the current process
Disable-AzContextAutosave -Scope Process

# Connect to Azure with the system-assigned managed identity that represents the Automation Account
Connect-AzAccount -TenantId $sourceTentantId

# Set the Azure Subscription context using Azure Subscription ID
Set-AzContext -SubscriptionId $sourceAzureSubscriptionId

# Create a new Azure Storage Context for the source storage account using Azure AD authentication
$sourceContext = New-AzStorageContext -StorageAccountName $sourceStorageAccountName -UseConnectedAccount -EnableFileBackupRequestIntent

# Get all Azure Files shares using the Storage Context and save as an array in a variable
$shares = Get-AzStorageShare -Context $sourceContext

# Initialize an array to hold file information
$fileInfoList = @()

# Function to process files and directories
function ProcessFilesAndDirs($filesAndDirs) {
    foreach ($f in $filesAndDirs) {
        $jsonFilePath = "./$($f.Name).json"
        $f | ConvertTo-Json -Depth 100 | Out-File -FilePath $jsonFilePath

        if ($f.GetType().Name -eq "AzureStorageFile") {
            $filePath = $($f.ShareFileClient.Path)
            $shareName = $($f.ShareFileClient.ShareName)
            $fileProperties = Get-AzStorageFile -ShareName $shareName -Path $filePath -Context $sourceContext # Fetch file properties
            $fileSizeBytes = $fileProperties.Length # Get the file size
            $fileSizeMB = [math]::Round($fileSizeBytes / 1MB, 2) # Convert to megabytes and round to 2 decimal places
            $folderPath = Split-Path -Path $filePath -Parent # Get the folder path
            $fileName = Split-Path -Path $filePath -Leaf # Get the file name

            # Add file information to the array
            $global:fileInfoList += [PSCustomObject]@{
                ShareName = $shareName
                FolderPath = $folderPath
                FileName = $fileName
                FileSizeMB = $fileSizeMB
            }

            # Delete each "File" JSON file after processing to prevent large local storage consumption
            Remove-Item -Path $jsonFilePath -Force
        }
        elseif ($f.GetType().Name -eq "AzureStorageFileDirectory") {
            list_subdir($f)

                        # Delete each "Directory" JSON file after processing to prevent large local storage consumption
                        Remove-Item -Path $jsonFilePath -Force
        }
      

    }
}

# Function to list sub-directories to recursively get all files and directories
function list_subdir([Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageFileDirectory]$dirs) {
    $path = $dirs.ShareDirectoryClient.Path
    $shareName = $dirs.ShareDirectoryClient.ShareName
    $filesAndDirs = Get-AzStorageFile -ShareName "$shareName" -Path "$path" -Context $sourceContext | Get-AzStorageFile
    ProcessFilesAndDirs $filesAndDirs
}

# Iterate through all Azure Files shares in the $shares variable with array data type
foreach ($share in $shares) {
    $shareName = $share.Name
    $filesAndDirs = Get-AzStorageFile -ShareName $shareName -Context $sourceContext
    ProcessFilesAndDirs $filesAndDirs
}

# Export the file information to a CSV file
$fileInfoList | Export-Csv -Path "AzureFiles-Consumption.csv" -NoTypeInformation