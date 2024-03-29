# Ref: https://learn.microsoft.com/en-us/fslogix/reference-configuration-settings?tabs=odfc#app-services-settings
#      https://learn.microsoft.com/en-us/fslogix/configure-office-container-tutorial
#      
#      FSLogix 2210 hotfix https://learn.microsoft.com/en-us/fslogix/whats-new#fslogix-2210-hotfix-1-29844042104
#      there is a known issue observed in the recent Fslogix version related to office application login. 
#      Users may be required to authenticate to their applications (for example, Microsoft 365 apps, Teams (work or school), OneDrive, etc.) at every sign-in.
#
# GPO regkey https://gpsearch.azurewebsites.net/
#
# # If done via custom extention
# # .\\avd_fslogix.ps1 -ProfilePath "\\lvolkfiles.file.core.windows.net\garbage" - LocalWVDpath "C:\installers\FsLogix\x64\Release" -Verbose 

Param (
    [string]$ProfilePath,
    [string]$RedirectXML
)

# $ProfilePath = "\\imagesaaad.file.core.windows.net\avdprofiles1"
# $RedirectXML = "\\imagesaaad.file.core.windows.net\appmaskrules"

#########################################
$LocalWVDpath            = "c:\tempavd"
if((Test-Path $LocalWVDpath) -eq $false) {
    New-Item -Path $LocalWVDpath -ItemType Directory
}


##########################################
#    Log Function                        #
##########################################
$logFile = "$LocalWVDpath" + (get-date -format 'yyyyMMdd') + '_fslogix_install.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}

######################
#    AVD Variables   #
######################
$FSLogixURI              = 'https://aka.ms/fslogix_download'
$FSInstaller             = 'FSLogixAppsSetup.zip'

#################################
#    Download AVD Componants    #
#################################
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Invoke-WebRequest -Uri $FSLogixURI -OutFile "$LocalWVDpath\$FSInstaller"

##############################
#    Prep for WVD Install    #
##############################
Expand-Archive `
    -LiteralPath "$LocalWVDpath\$FSInstaller" `
    -DestinationPath "$LocalWVDpath\FSLogix" `
    -Force `
    -Verbose

Set-Location -Path "$LocalWVDpath\FSLogix\x64\Release"

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
        -Value "15000"
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
    # Set-ItemProperty `
    #     -Path HKLM:\Software\FSLogix\Profiles `
    #     -Name "SIDDirNamePattern" `
    #     -Type String `
    #     -Value "%username%%sid%"
    # Set-ItemProperty `
    #     -Path HKLM:\Software\FSLogix\Profiles `
    #     -Name "SIDDirNameMatch" `
    #     -Type String `
    #     -Value "%username%%sid%"
    Set-ItemProperty `
        -Path HKLM:\Software\FSLogix\Profiles `
        -Name DeleteLocalProfileWhenVHDShouldApply `
        -Type DWord `
        -Value 1
    Set-ItemProperty `
        -Path HKLM:\Software\FSLogix\Profiles `
        -Name "ProfileType" `
        -Type "Dword" `
        -Value "3"
    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\Software\FSLogix\Profiles" `
        -Name "RoamIdentity" `
        -Type "Dword" `
        -Value "1" `
        -Force `
        -Confirm:$false

Write-Output  "Done with FSLogix User Profile Settings"



# The redirections.xml file only works in conjunction with a Profile Container, not with the Office container. 
# Ref: https://learn.microsoft.com/en-us/fslogix/profile-container-office-container-cncpt
#######################################
#    FSLogix -- Profile Container --
#    Set Office RedirXMLSourceFolder
#######################################
    New-ItemProperty -ErrorAction Stop `
        -Path HKLM:\SOFTWARE\FSLogix\Profiles `
        -Name "RedirXMLSourceFolder" `
        -PropertyType Multistring `
        -Value $RedirectXML `
        -Force `
        -Confirm:$false

    # OneDrive Configuration  https://admx.help/?Category=OneDrive&Policy=Microsoft.Policies.OneDriveNGSC::BlockKnownFolderMove
    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" `
        -Name "FilesOnDemandEnabled" `
        -Type "Dword" `
        -Value "1" `
        -Force `
        -Confirm:$false
    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" `
        -Name "MinDiskSpaceLimitInMB" `
        -Type "Dword" `
        -Value "2000" `
        -Force `
        -Confirm:$false
    # New-ItemProperty -ErrorAction Stop `
    #     -Path "HKCU:\SOFTWARE\Policies\Microsoft\OneDrive" `
    #     -Name "DisableCustomRoot" `
    #     -Type "Dword" `
    #     -Value "1" `
    #     -Force `
    #     -Confirm:$false
    # New-ItemProperty -ErrorAction Stop `
    #     -Path "HKCU:\Policies\Microsoft\OneDrive" `
    #     -Name "DisableTutorial" `
    #     -Type "Dword" `
    #     -Value "1" `
    #     -Force `
    #     -Confirm:$false

#######################################
#    FSLogix ODFS -- Office Container --         
#    Office Container is generally implemented with another profile solution, 
#    and is designed to improve the performance of Microsoft Office in non-persistent environments
#    https://learn.microsoft.com/en-us/fslogix/concepts-container-types?source=recommendations#odfc-container
#    https://learn.microsoft.com/en-us/fslogix/concepts-container-types#when-to-use-profile-and-odfc-containers
#######################################
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "Enabled" `
#         -Value "1" -PropertyType DWORD `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "VHDLocations" `
#         -PropertyType Multistring `
#         -Value "$ProfilePath" `
#         -Force `
#         -Confirm:$false

#     # Set the Teams Registry key (for win11-22h2-avd-m365 by default)
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Microsoft\Teams" `
#         -Name "IsWVDEnvironment" `
#         -Value "1" -PropertyType DWORD `
#         -Force `
#         -Confirm:$false
#     #User will be required to sign in to teams at the beginning of each session if set to 0
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "IncludeTeams" `
#         -Type "Dword" `
#         -Value "0" `
#         -Force `
#         -Confirm:$false
#     # Ref https://learn.microsoft.com/en-us/fslogix/configure-office-container-tutorial
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "VHDAccessMode" `
#         -Value "0" -PropertyType DWORD `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "VolumeType" `
#         -Type String `
#         -Value "vhdx" `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "SizeInMBs" `
#         -Type "Dword" `
#         -Value "10000" `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "IsDynamic" `
#         -Value "1" `
#         -PropertyType DWORD `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "FlipFlopProfileDirectoryName" `
#         -Type "Dword" `
#         -Value "1" `
#         -Force `
#         -Confirm:$false
# # if enabled MSTSC connection would fail
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "PreventLoginWithFailure" `
#         -Type "Dword" `
#         -Value "0" `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "IncludeOneDrive" `
#         -Type "Dword" `
#         -Value "0" `
#         -Force `
#         -Confirm:$false

#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "IncludeOneNote" `
#         -Type "Dword" `
#         -Value "0" `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "IncludeOneNote_UWP" `
#         -Type "Dword" `
#         -Value "0" `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "IncludeOutlook" `
#         -Type "Dword" `
#         -Value "0" `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "IncludeOutlookPersonalization" `
#         -Type "Dword" `
#         -Value "1" `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "IncludeSharepoint" `
#         -Type "Dword" `
#         -Value "0" `
#         -Force `
#         -Confirm:$false
#     New-ItemProperty -ErrorAction Stop `
#         -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" `
#         -Name "IncludeOfficeActivation" `
#         -Type "Dword" `
#         -Value "1" `
#         -Force `
#         -Confirm:$false

# Write-Output  "Done with FSLogix Office Container Settings"

### REF https://learn.microsoft.com/en-us/fslogix/reference-configuration-settings?tabs=odfc#app-services-settings
    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\FSLogix\Apps" `
        -Name "CleanupInvalidSessions" `
        -Type "Dword" `
        -Value "0" `
        -Force `
        -Confirm:$false
    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\FSLogix\Apps" `
        -Name "RoamRecycleBin" `
        -Type "Dword" `
        -Value "0" `
        -Force `
        -Confirm:$false
    # https://learn.microsoft.com/en-us/fslogix/concepts-vhd-disk-compaction
    New-ItemProperty -ErrorAction Stop `
        -Path "HKLM:\SOFTWARE\FSLogix\Apps" `
        -Name "VHDCompactDisk" `
        -Type "Dword" `
        -Value "0" `
        -Force `
        -Confirm:$false

Write-Output  "Done with App Services Settings"

Write-output "Restarting host: $env:computername"

Restart-Computer -Force

}

catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding profile settings registry KEY: $ErrorMessage"
    Write-Output "***** Error adding profile settings registry KEY: $ErrorMessage"
}
