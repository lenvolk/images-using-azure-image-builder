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
.\azcopy.exe sync "C:\Temp" "https://volksa.blob.core.windows.net/source1" --recursive

.\azcopy.exe copy "https://volksa.blob.core.windows.net" "https://memnmaintemain032800470.blob.core.windows.net" --recursive=true

.\azcopy.exe logout

schtasks /CREATE /SC minute /MO 5 /TN "AzCopy Script" /TR "C:\Temp\azcopy.bat"