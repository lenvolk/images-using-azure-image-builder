
####################################
# Setup wvd agents
####################################


# $blobUri = "<__param1__>"
# $sasToken = "<__param2__>"
# $blob = "<__param3__>"

$storageAccount = "<__param1__>"
$container = "<__param2__>"
$blob = "<__param3__>"

Write-Host `
    -ForegroundColor Yellow `
    -BackgroundColor Green `
    write-host "##############wvd_downloading_new_binary with params: ################################"
# write-host "blobUri set to: $blobUri"
# write-host "&&&&&&& sasToken set to: $sasToken"
# write-host "blob set to: $blob"
write-host "storageAccount set to: $storageAccount"
write-host "container set to: $container"
write-host "blob set to: $blob"

if ((Test-Path c:\temp) -eq $false) {
    Add-Content -LiteralPath C:\New-WVDBinary.log "Create C:\temp Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Green `
        "creating temp directory"
    New-Item -Path c:\temp -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\New-WVDBinary.log "C:\temp Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Green `
        "temp directory already exists"
}

#T-Shooting
# Add-Content -LiteralPath C:\New-WVDBinary.log "BlobUri is $blobUri AND sasToken is $sasToken AND blob is $blob"

# invoke-webrequest -uri 'https://aka.ms/downloadazcopy-v10-windows' -OutFile 'c:\temp\azcopy.zip'
# Expand-Archive 'c:\temp\azcopy.zip' 'c:\temp'
# copy-item 'C:\temp\azcopy_windows_amd64_*\azcopy.exe\' -Destination 'c:\temp'

# Add-Content -LiteralPath C:\New-WVDBinary.log "downloaded azcopy to c:\temp"
# Write-Host `
#     -ForegroundColor Yellow `
#     -BackgroundColor Green `
#     "downloaded azcopy to c:\temp"
#
#C:\installers\azcopy.exe copy "$blobUri$sasToken" C:\installers\WVDAgent\$blob --overwrite true --recursive
#
# replace https://imageartifactsa01.privatelink.blob.core.windows.net
#
# $blobUri = $blobUri -replace ".blob.core.windows.net", ".privatelink.blob.core.windows.net"
# Write-Host `
#     -ForegroundColor Yellow `
#     -BackgroundColor Green `
#     "updated bloburi is $blobUri"

# $uri = $blobUri + $sasToken
# Write-Host `
#     -ForegroundColor Yellow `
#     -BackgroundColor Green `
#     "uri is $uri"

# invoke-webrequest -uri $uri -UseBasicParsing -OutFile c:\temp\$blob
# Expand-Archive "c:\temp\$blob" -DestinationPath "C:\temp" -Force -Verbose

# Add-Content -LiteralPath C:\New-WVDBinary.log "downloading binary from blob to c:\temp and extract it"
# Write-Host `
#     -ForegroundColor Yellow `
#     -BackgroundColor Green `
#     "downloading binary from blob to c:\temp and extract it"

$uri = "https://$storageAccount.blob.core.windows.net/$container/$blob"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

invoke-webrequest -uri $uri -OutFile c:\temp\$blob

Expand-Archive `
    -LiteralPath "C:\temp\$blob" `
    -DestinationPath "C:\installers\QMessenger7" `
    -Force `
    -Verbose

Add-Content -LiteralPath C:\New-WVDBinary.log "downloading QMessanger binary from blob to c:\temp and extract it"
Write-Host `
    -ForegroundColor Yellow `
    -BackgroundColor Green `
    "downloading binary from blob to c:\temp and extract it"

Write-Host `
    -ForegroundColor Yellow `
    -BackgroundColor Green `
    "run QMessenger7 installer"

REG ADD "HKU\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "qmessenger7" /t REG_EXPAND_SZ /d "C:\Installers\QMessenger7\q7-installer-windows.exe" /f


#### RSAT ####
# Add-Content -LiteralPath C:\New-WVDBinary.log "downloading binary from blob to c:\temp and extract it"
# Write-Host `
#     -ForegroundColor Yellow `
#     -BackgroundColor Green `
#     "downloading binary from blob to c:\temp and extract it"

# Write-Host `
#     -ForegroundColor Yellow `
#     -BackgroundColor Green `
#     "run RSAT installer"

# $blob = "WindowsTH-RSAT_WS_1709-x64.msu"


# wusa "c:\temp\$blob" /quiet /norestart

# Write-Host `
#     -ForegroundColor Yellow `
#     -BackgroundColor Green `
#     "waiting for RSAT to be installed" 

# while (-not (get-module -list activedirectory)) {
#     ## Wait a specific interval
#     Start-Sleep -Seconds 5
# }

# Write-Host `
#     -ForegroundColor Yellow `
#     -BackgroundColor Green `
#     "RSAT installed: " 
# if (get-module -list activedirectory) { 'found' }