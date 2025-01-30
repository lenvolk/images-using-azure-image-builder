Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose

$logFile = "c:\installers\" + (get-date -format 'yyyyMMdd') + '_softwareinstall.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}

set-location C:\installers
Import-Certificate -FilePath '.\ATT Palo Alto Proxy Root CA.cer' -CertStoreLocation Cert:\LocalMachine\Root


#set-location C:\installers\TLSsettings
#.\SCProtocol.ps1

set-location C:\installers\CloudPassage
.\InstallCWSPC.ps1

# set-location C:\installers\FsLogix\x64\Release
# $fslogixsetup = "FSLogixAppsSetup.exe", "FSLogixAppsRuleEditorSetup.exe"  #,"FSLogixAppsJavaRuleEditorSetup.exe"
# foreach ($f in $fslogixsetup) {
#     $cmd = "$($f) /install /quiet /norestart"
#     #Invoke-Expression -Command $cmd | Out-Null
#     start-process -FilePath "cmd " -ArgumentList "/c $cmd" -Wait
# }

# New-Item HKLM:\SOFTWARE\FSLogix -Name Profiles
# New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name Enabled -PropertyType DWORD -Value 1
# New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name VHDLocations -PropertyType Multistring -Value "\\$fslogix_share"
# New-ItemProperty -Path HKLM:\SOFTWARE\FSLogix\Profiles -Name DeleteLocalProfileWhenVHDShouldApply -PropertyType DWORD -Value 1


set-location C:\installers\firefox
$ffexe = "Firefox.msi"
$ffcmd = "/i $ffexe /quiet /norestart"
Start-Process -FilePath "msiexec" -ArgumentList $ffcmd -Wait


# Denver to take a look at https://docs.microsoft.com/en-us/azure/virtual-desktop/install-office-on-wvd-master-image#sample-configurationxml


set-location C:\installers\Office

$officesetup = "setup.exe"

#Invoke-Expression -Command $cmd | Out-Null
start-process -FilePath $officesetup -ArgumentList "/configure config.xml" -Wait


set-location C:\installers\ForcepointDLP
$fpsetup = "FF-F1E-20.02.4887-x64.exe"
start-process -FilePath $fpsetup -ArgumentList '/v"/qn /norestart"' -Wait
rem Mount the default user registry hive
reg load HKU\TempDefault C:\Users\Default\NTUSER.DAT
rem Must be executed with default registry hive mounted.
reg add HKU\TempDefault\SOFTWARE\Policies\Microsoft\office\16.0\common /v InsiderSlabBehavior /t REG_DWORD /d 2 /f
rem Set Outlooks Cached Exchange Mode behavior
rem Must be executed with default registry hive mounted.
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v enable /t REG_DWORD /d 1 /f
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v syncwindowsetting /t REG_DWORD /d 1 /f
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v CalendarSyncWindowSetting /t REG_DWORD /d 1 /f
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v CalendarSyncWindowSettingMonths  /t REG_DWORD /d 1 /f
rem Unmount the default user registry hive
reg unload HKU\TempDefault

rem Set the Office Update UI behavior.
reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideupdatenotifications /t REG_DWORD /d 1 /f
reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideenabledisableupdates /t REG_DWORD /d 1 /f

# set-location C:\installers\FireEye
# $fireeyesetup="xagtSetup_31.28.8_universal.msi"
# $fireyecmd = "/i $fireeyesetup /quiet /norestart /l* fe.log"
# start-process -FilePath "msiexec" -ArgumentList $fireyecmd -Wait

try {
    Start-Process -filepath 'C:\installers\notepad\npp.7.8.8.Installer.x64.exe' -Wait -ErrorAction Stop -ArgumentList '/S'
    Copy-Item 'C:\installers\notepad\config.model.xml' 'C:\Program Files\Notepad++'
    Rename-Item 'C:\Program Files\Notepad++\updater' 'C:\Program Files\Notepad++\updaterOld'
    if (Test-Path "C:\Program Files\Notepad++\notepad++.exe") {
        Write-Log "Notepad++ has been installed"
    }
    else {
        write-log "Error locating the Notepad++ executable"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing Notepad++: $ErrorMessage"
}