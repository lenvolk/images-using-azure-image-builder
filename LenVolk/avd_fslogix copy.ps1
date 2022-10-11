############ For ADO PP
#
# https://aka.ms/fslogix-latest
# 
# location of teams "redirections.xml" https://wvdpocprofilesa.file.core.windows.net/wvdnonpersistent
# .\\wvd_fslogix.ps1 -ProfilePath "\\wvdpocprofilesa.file.core.windows.net\wvdnonpersistent" - LocalWVDpath "C:\installers\FsLogix\x64\Release" -Verbose 
# write-host 'Finished Fslogix installer' 
#
#
# $ProfilePath = "\\wvdpocprofilesa.file.core.windows.net\wvdnonpersistent"
# Param (        
#     [Parameter(Mandatory = $true)]
#     [string]$ProfilePath,
#     [string]$RedirXML,
#     [string]$LocalWVDpath
# )   
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose

############ For Packer
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose

$ProfilePath = [Environment]::GetEnvironmentVariable('ProfilePath')
$RedirXML = [Environment]::GetEnvironmentVariable('RedirXML')
$LocalWVDpath = [Environment]::GetEnvironmentVariable('LocalWVDpath')

$ProfilePath = "\\" + $ProfilePath.replace(" ", "")
$RedirXML = "\\" + $RedirXML.replace(" ", "")

#########################
#    FSLogix Install    #
#########################
# Add-Content -LiteralPath C:\New-WVDSessionHost.log "Installing FSLogix and configuring regkeys"
# $fslogix_deploy_status = Start-Process `
#     -FilePath "$LocalWVDpath\FSLogixAppsSetup.exe" `
#     -ArgumentList "/install /quiet" `
#     -Wait `
#     -Passthru

set-location C:\installers\FsLogix\x64\Release

$fslogixsetup = "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe"  #,"FSLogixAppsJavaRuleEditorSetup.exe"

foreach ($f in $fslogixsetup) {
    $cmd = "$($f) /install /quiet /norestart"
    #Invoke-Expression -Command $cmd | Out-Null
    start-process -FilePath "cmd " -ArgumentList "/c $cmd" -Wait

}

##########################################
#    Set C:\temp                         #
##########################################

# if ((Test-Path c:\temp) -eq $false) {
#     Add-Content -LiteralPath C:\New-WVDSetup.log "Create C:\temp Directory"
#     Write-Host `
#         -ForegroundColor Cyan `
#         -BackgroundColor Green `
#         "creating temp directory"
#     New-Item -Path c:\temp -ItemType Directory
# }
# else {
#     Add-Content -LiteralPath C:\New-WVDSetup.log "C:\temp Already Exists"
#     Write-Host `
#         -ForegroundColor Yellow `
#         -BackgroundColor Green `
#         "temp directory already exists"
# }

if (!(Test-Path "c:\temp")) {
    New-Item -Type Directory -Path 'c:\' -Name "temp"
}

##########################################
#    Log Function                        #
##########################################
$logFile = "c:\temp\" + (get-date -format 'yyyyMMdd') + '_regkey_modify.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}

##########################################
#    Hide drives A, D, E                 #
##########################################

$name = "NoDrives"
$value = "25" #1+8+16=25
# Add Registry value
try {

    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
        -Name $name `
        -Value $value `
        -PropertyType DWORD `
        -Force `
        -Confirm:$false


    if ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer").PSObject.Properties.Name -contains $name) {
        Write-log "Added time zone redirection registry key"
        Write-Output "***** Hiding drives"
    }
    else {
        write-log "Error locating the Teams registry key"
        Write-Output "***** Error locating the NoDrives regkey"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding hide drive registry KEY: $ErrorMessage"
    Write-Output "***** Error adding hide drive registry KEY: $ErrorMessage"
}

##########################################
#    Sessions Control                    #
##########################################
$Name = "MaxDisconnectionTime"
# Add Registry value
try {

    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
        -Name $Name `
        -Value "1800000" `
        -PropertyType DWORD `
        -Force `
        -Confirm:$false


    if ((Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services").PSObject.Properties.Name -contains $name) {
        Write-log "Added Max Disconnected Time registry key"
        Write-Output "Added Max Disconnected Time registry key"
    }
    else {
        write-log "Error locating the Time Disconnect registry key"
        Write-Output "***** Error locating the Time Disconnect registry key"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding Time Disconnect registry key: $ErrorMessage"
    Write-Output "***** Error adding Time Disconnect registry key: $ErrorMessage"
}


$Name = "RemoteAppLogoffTimeLimit"
# Add Registry value
try {

    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
        -Name $Name `
        -Value "1800000" `
        -PropertyType DWORD `
        -Force `
        -Confirm:$false


    if ((Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services").PSObject.Properties.Name -contains $name) {
        Write-log "Added Max Remote App LogOff Time registry key"
        Write-Output "Added Max Remote App LogOff Time registry key"
    }
    else {
        write-log "Error locating the Remote App LogOff Time registry key"
        Write-Output "***** Error locating the Remote App LogOff Time registry key"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding Remote App LogOff Time registry key: $ErrorMessage"
    Write-Output "***** Error adding Remote App LogOff Time registry key: $ErrorMessage"
}

$Name = "MaxIdleTime"
# Add Registry value
try {

    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
        -Name $Name `
        -Value "7200000" `
        -PropertyType DWORD `
        -Force `
        -Confirm:$false

    if ((Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services").PSObject.Properties.Name -contains $name) {
        Write-log "Added Max Idle Time registry key"
        Write-Output "Added Max Idle Time registry key"
    }
    else {
        write-log "Error locating the Max Idle Time registry key"
        Write-Output "***** Error locating the Max Idle Time registry key"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding Max Idle Time registry key: $ErrorMessage"
    Write-Output "***** Error adding Max Idle Time registry key: $ErrorMessage"
}

##########################################
#    Region Time Zone Redirection        #
##########################################

$Name = "fEnableTimeZoneRedirection"
$value = "1"
# Add Registry value
try {
    New-ItemProperty -ErrorAction Stop -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name $name -Value $value -PropertyType DWORD -Force
    if ((Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services").PSObject.Properties.Name -contains $name) {
        Write-log "Added time zone redirection registry key"
        Write-Output "***** Added time zone redirection registry key"
    }
    else {
        write-log "Error locating the Time registry key"
        Write-Output "***** Error locating the Time registry key"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding Time registry KEY: $ErrorMessage"
    Write-Output "***** Error adding Time registry KEY: $ErrorMessage"
}


##########################################
#    FSLogix Profile Path                #
##########################################

try {
    # Set FSLogix share
    if (!(Test-Path "HKLM:\SOFTWARE\FSLogix\Profiles")) {
        New-Item -ErrorAction Stop -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Force 
    }
    else {
        write-log "Created FSLogix Profile path registry key"
        Write-Output "***** Created FSLogix Profile path registry key"
    }

}

catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding FSLogix Profile and Redirection path registry KEY: $ErrorMessage"
    Write-Output "***** Error adding FSLogix Profile and Redirection path registry KEY: $ErrorMessage"
}

##########################################
#    Teams WVD settings Path             #
##########################################

try {

    # Add Registry Path
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Teams")) {
        New-Item -ErrorAction Stop -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Force 
    }
    else {
        write-log "Created Teams registry key"
        Write-Output "***** Created Teams registry key"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding teams path registry KEY: $ErrorMessage"
    Write-Output "***** Error adding teams path registry KEY: $ErrorMessage"
}


##########################################
#    Enable Screen Capture Protection    #
##########################################
# $name = "fEnableScreenCaptureProtection"
# $value = "1"

# try {

#     Push-Location 
#     Set-Location "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
#     New-ItemProperty `
#         -Path .\ `
#         -Name $name `
#         -Value $value `
#         -PropertyType DWord `
#         -Force
#     Pop-Location

#     if ((Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services").PSObject.Properties.Name -contains $name) {
#         Write-log "Added screen capture protection registry key"
#         Write-Output "***** Added screen capture protection registry key"
#     }
#     else {
#         write-log "Error locating screen capture protection registry key"
#         Write-Output "***** Error locating screen capture protection registry key"
#     }

# }
# catch {
#     $ErrorMessage = $_.Exception.message
#     write-log "Error adding Screen Capture registry KEY: $ErrorMessage"
#     Write-Output  "***** Error adding Screen Capture registry KEY: $ErrorMessage"
# }



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

    # Set Office RedirXMLSourceFolder
    # New-ItemProperty -ErrorAction Stop `
    #     -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    #     -Name "RedirXMLSourceFolder" `
    #     -PropertyType Multistring `
    #     -Value "$RedirXML" `
    #     -Force `
    #     -Confirm:$false

    # Set the Teams Registry key
    # New-ItemProperty -ErrorAction Stop `
    #     -Path "HKLM:\SOFTWARE\Microsoft\Teams" `
    #     -Name "IsWVDEnvironment" `
    #     -Value "1" -PropertyType DWORD `
    #     -Force `
    #     -Confirm:$false

    # Cloud Cache redirection, if Enabled VHDLocations needs to be disabled
    # New-ItemProperty `
    #     -Path HKLM:\Software\FSLogix\Profiles `
    #     -Name "CCDLocations" `
    #     -Value "type=smb,connectionString=$ProfilePath;type=smb,connectionString=$DR_ProfilePath" `
    #     -PropertyType MultiString `
    #     -Force `
    #     -Confirm:$false

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



### !!!!! review wvd_regkey.ps1