#######################################
#              AzCopy                  #
#######################################
# # download azcopy https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10#download-azcopy
# Set-Location -Path "C:\Temp"
# Invoke-WebRequest -Uri 'https://azcopyvnext.azureedge.net/release20220315/azcopy_windows_amd64_10.14.1.zip' -OutFile 'azcopyv10.zip'
# Expand-archive -Path '.\azcopyv10.zip' -Destinationpath '.\'
# $AzCopy = (Get-ChildItem -path '.\' -Recurse -File -Filter 'azcopy.exe').FullName
# # Invoke AzCopy 
# & $AzCopy

# azcopy with MSI
# SA IAM: Storage Blob Data Reader OR Storage Blob Data Owner + Storage Account Contributor to VM's Identity   
.\azcopy.exe login --identity

.\azcopy.exe make 'https://volksa.blob.core.windows.net/source1'
.\azcopy.exe list 'https://volksa.blob.core.windows.net/source1'
.\azcopy.exe sync "C:\Temp" "https://volksa.blob.core.windows.net/source1" --recursive

.\azcopy.exe copy "https://volksa.blob.core.windows.net" "https://memnmaintemain032800470.blob.core.windows.net" --recursive=true

.\azcopy.exe logout

schtasks /CREATE /SC minute /MO 5 /TN "AzCopy Script" /TR "C:\Temp\azcopy.bat"


######


az role assignment create --assignee <managed-identity-id> --role "Storage Blob Data Contributor" --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>

az role assignment create --assignee <managed-identity-id> --role "Reader" --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>

(might need to add role Storage Blob Data Reader to RG where SA is for arc MSI
Add your login account to the SA with Storage Blob Data Reader )

az account clear
az login --identity

az storage account show -n fileservervolk --query networkRuleSet

#upload single file
az storage blob upload --account-name fileservervolk --container-name sharepoint --name example2.txt --file C:\temp\example.txt --auth-mode login

#upload folder
az storage blob upload-batch --account-name fileservervolk --destination sharepoint --source C:\temp --overwrite --auth-mode login

#sync folder
# .\azcopy -h
.\azcopy login --identity
.\azcopy sync "C:\Temp\sharepoint" "https://fileservervolk.blob.core.windows.net/sharepoint"


az storage blob list --account-name fileservervolk --container-name sharepoint --output table --auth-mode login
