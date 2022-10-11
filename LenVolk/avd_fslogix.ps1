# If done via custom extention
# .\\wvd_fslogix.ps1 -ProfilePath "\\lvolkfiles.file.core.windows.net\garbage" - LocalWVDpath "C:\installers\FsLogix\x64\Release" -Verbose 

##########################################
#    Log Function                        #
##########################################
$logFile = "c:\temp\" + (get-date -format 'yyyyMMdd') + '_fslogix_install.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}

######################
#    WVD Variables   #
######################
$LocalWVDpath            = "c:\temp\"
$FSLogixURI              = 'https://aka.ms/fslogix_download'
$FSInstaller             = 'FSLogixAppsSetup.zip'
$ProfilePath             = "\\lvolkfiles.file.core.windows.net\garbage"

#################################
#    Download WVD Componants    #
#################################
Invoke-WebRequest -Uri $FSLogixURI -OutFile "$LocalWVDpath$FSInstaller"

##############################
#    Prep for WVD Install    #
##############################

Expand-Archive `
    -LiteralPath "C:\temp\$FSInstaller" `
    -DestinationPath "$LocalWVDpath\FSLogix" `
    -Force `
    -Verbose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

cd "$LocalWVDpath\FSLogix\x64\Release"

$fslogixsetup = "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe"

try {
    foreach ($f in $fslogixsetup) {
        $cmd = "$($f) /install /quiet /norestart"
        #Invoke-Expression -Command $cmd | Out-Null
        start-process -FilePath "cmd " -ArgumentList "/c $cmd" -Wait
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing fslogix: $ErrorMessage"
    #Write-Output "***** Error installing fslogix: $ErrorMessage"
}


#######################################
#    FSLogix User Profile Settings    #
#######################################

try {

    # Add FSLogix Profile Registry Value
    New-ItemProperty -ErrorAction Stop `
        -Path HKLM:\SOFTWARE\FSLogix\Profiles `
        -Name "VHDLocations" `
        -PropertyType Multistring `
        -Value "$ProfilePath" `
        -Force `
        -Confirm:$false

    Set-ItemProperty `
        -Path HKLM:\Software\FSLogix\Profiles `
        -Name "Enabled" `
        -Type "Dword" `
        -Value "1"
    Set-ItemProperty `
        -Path HKLM:\Software\FSLogix\Profiles `
        -Name "SizeInMBs" `
        -Type "Dword" `
        -Value "10000"
    Set-ItemProperty `
        -Path HKLM:\Software\FSLogix\Profiles `
        -Name "IsDynamic" `
        -Type "Dword" `
        -Value "1"
    Set-ItemProperty `
        -Path HKLM:\Software\FSLogix\Profiles `
        -Name "VolumeType" `
        -Type String `
        -Value "vhdx"
    Set-ItemProperty `
        -Path HKLM:\Software\FSLogix\Profiles `
        -Name "FlipFlopProfileDirectoryName" `
        -Type "Dword" `
        -Value "1" 
    Set-ItemProperty `
        -Path HKLM:\Software\FSLogix\Profiles `
        -Name "SIDDirNamePattern" `
        -Type String `
        -Value "%username%%sid%"
    Set-ItemProperty `
        -Path HKLM:\Software\FSLogix\Profiles `
        -Name "SIDDirNameMatch" `
        -Type String `
        -Value "%username%%sid%"
    Set-ItemProperty `
        -Path HKLM:\Software\FSLogix\Profiles `
        -Name DeleteLocalProfileWhenVHDShouldApply `
        -Type DWord `
        -Value 1

    Write-Output  "Done with FSLogix User Profile Settings"

}

catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding profile settings registry KEY: $ErrorMessage"
    Write-Output "***** Error adding profile settings registry KEY: $ErrorMessage"
}








write-host 'AIB Customization: Downloading FsLogix'
New-Item -Path C:\\ -Name fslogix -ItemType Directory -ErrorAction SilentlyContinue
$LocalPath = 'C:\\fslogix'
$WVDflogixURL = 'https://raw.githubusercontent.com/DeanCefola/Azure-WVD/master/PowerShell/FSLogixSetup.ps1'
$WVDFslogixInstaller = 'FSLogixSetup.ps1'
$outputPath = $LocalPath + '\' + $WVDFslogixInstaller
Invoke-WebRequest -Uri $WVDflogixURL -OutFile $outputPath
set-Location $LocalPath

$fsLogixURL="https://aka.ms/fslogix_download"
$installerFile="fslogix_download.zip"

Invoke-WebRequest $fsLogixURL -OutFile $LocalPath\$installerFile
Expand-Archive $LocalPath\$installerFile -DestinationPath $LocalPath
write-host 'AIB Customization: Download Fslogix installer finished'

write-host 'AIB Customization: Start Fslogix installer'
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
.\\FSLogixSetup.ps1 -ProfilePath \\wvdSMB\wvd -Verbose 
write-host 'AIB Customization: Finished Fslogix installer' 