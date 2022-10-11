
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


### Setting the RDP Shortpath.
Write-Host 'Configuring RDP ShortPath'

$WinstationsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'

if (Test-Path $WinstationsKey) {
    New-ItemProperty -Path $WinstationsKey -Name 'fUseUdpPortRedirector' -ErrorAction:SilentlyContinue -PropertyType:dword -Value 1 -Force
    New-ItemProperty -Path $WinstationsKey -Name 'UdpPortNumber' -ErrorAction:SilentlyContinue -PropertyType:dword -Value 3390 -Force
}

Write-Host 'Settin up the Windows Firewall Rue for RDP ShortPath'
New-NetFirewallRule -DisplayName 'Remote Desktop - Shortpath (UDP-In)' -Action Allow -Description 'Inbound rule for the Remote Desktop service to allow RDP traffic. [UDP 3390]' -Group '@FirewallAPI.dll,-28752' -Name 'RemoteDesktop-UserMode-In-Shortpath-UDP' -PolicyStore PersistentStore -Profile Domain, Private -Service TermService -Protocol udp -LocalPort 3390 -Program '%SystemRoot%\system32\svchost.exe' -Enabled:True





### Maybe Add it too


# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose

# Write-Host "Disabling Automatic Updates..."
# reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d 1 -Force

# Write-Host "Moving pagefile.sys to D:\"
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name "PagingFiles" -Value "D:\pagefile.sys" -Type MultiString -Force

# # Enter the following commands into the registry editor to fix 5k resolution support
# reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxMonitors /t REG_DWORD /d 4 /f
# reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxXResolution /t REG_DWORD /d 5120 /f
# reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxYResolution /t REG_DWORD /d 2880 /f
# reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs" /v MaxMonitors /t REG_DWORD /d 4 /f
# reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs" /v MaxXResolution /t REG_DWORD /d 5120 /f
# reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs" /v MaxYResolution /t REG_DWORD /d 2880 /f


# Disable Storage Sense
# Write-Host "Disabling Storage Sense..."
# reg add HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy /v 01 /t REG_DWORD /d 0 /f

# # Remove the WinHTTP proxy
# netsh winhttp reset proxy

# # Set the power profile to the High Performance
# powercfg /setactive SCHEME_MIN

# Make sure that the environmental variables TEMP and TMP are set to their default values
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -name "TEMP" -Value "%SystemRoot%\TEMP" -Type ExpandString -force
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -name "TMP" -Value "%SystemRoot%\TEMP" -Type ExpandString -force

# # Set Windows services to defaults - This typically fails due to a permissions error, need to investigate why. May be due to differences in client vs Server os
# Set-Service -Name dhcp -StartupType Automatic
# Set-Service -Name IKEEXT -StartupType Automatic
# Set-Service -Name iphlpsvc -StartupType Automatic
# Set-Service -Name netlogon -StartupType Manual
# Set-Service -Name netman -StartupType Manual
# Set-Service -Name nsi -StartupType Automatic
# Set-Service -Name termService -StartupType Manual
# Set-Service -Name RemoteRegistry -StartupType Automatic
# Set-Service -Name Winrm -startuptype Automatic

# Ensure RDP is enabled
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0 -Type DWord -force
# Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "fDenyTSConnections" -Value 0 -Type DWord -force

# Set RDP Port to 3389 - Unnecessary for AVD due to reverse connect, but helpful for backdoor administration with a jump box 
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "PortNumber" -Value 3389 -Type DWord -force

# # Listener is listening on every network interface
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "LanAdapter" -Value 0 -Type DWord -force

# # Configure NLA
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1 -Type DWord -force
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "SecurityLayer" -Value 1 -Type DWord -force
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "fAllowSecProtocolNegotiation" -Value 1 -Type DWord -force

# # Set keep-alive value
# Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "KeepAliveEnable" -Value 1  -Type DWord -force
# Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "KeepAliveInterval" -Value 1  -Type DWord -force
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "KeepAliveTimeout" -Value 1 -Type DWord -force

# # Reconnect
# Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "fDisableAutoReconnect" -Value 0 -Type DWord -force
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "fInheritReconnectSame" -Value 1 -Type DWord -force
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "fReconnectSame" -Value 0 -Type DWord -force

# # Limit number of concurrent sessions
# Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "MaxInstanceCount" -Value 4294967295 -Type DWord -force

# Remove any self signed certs
# Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "SSLCertificateSHA1Hash" -force

# Turn on Firewall
# Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True

# # Allow WinRM
# REG add "HKLM\SYSTEM\CurrentControlSet\services\WinRM" /v Start /t REG_DWORD /d 2 /f
# net start WinRM
# Enable-PSRemoting -force
# Set-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -Enabled True

# # Allow RDP
# Set-NetFirewallRule -DisplayGroup "Remote Desktop" -Enabled True

# # Enable File and Printer sharing for ping
# Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True