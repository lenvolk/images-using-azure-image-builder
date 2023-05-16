
#REF https://robinhobo.com/how-to-shadow-an-active-user-session-in-windows-virtual-desktop-via-remote-desktop-connection-mstc/
# https://christiaanbrinkhoff.com/2020/06/19/learn-about-the-different-options-to-remote-control-shadow-your-windows-virtual-desktop-sessions-for-helpdesk-users/

$WinstationsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
$name1 = 'fDenyTSConnections'

if ((Get-ItemProperty $WinstationsKey).PSObject.Properties.Name -contains $name1) {
     Write-Output "updating regkey $name1"
     New-ItemProperty -Path $WinstationsKey -Name $name1 -ErrorAction:SilentlyContinue -PropertyType:dword -Value 0 -Force
}
else {
    Write-Output "***** regkey name: $name1 not found"
}

# # Ref http://remotedesktoprdp.com/force-single-session-allow-multiple-sessions-per-user
# $name2 = 'fSingleSessionPerUser'
# if ((Get-ItemProperty $WinstationsKey).PSObject.Properties.Name -contains $name2) {
#     Write-Output "updating regkey $name2"
#     New-ItemProperty -Path $WinstationsKey -Name $name2 -ErrorAction:SilentlyContinue -PropertyType:dword -Value 0 -Force
# }
# else {
#    Write-Output "***** regkey name: $name2 not found"
# }

Netsh advfirewall firewall set rule group=”remote desktop” new enable=yes


mstsc.exe /shadow:2 /v:ChocoWin11m365 /control #/noConsentPrompt