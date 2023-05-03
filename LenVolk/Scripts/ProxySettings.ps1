
Param (
    [string]$ProxyServer
)

# $ProxyServer = "10.199.0.19:3128"
# "\\lvolk.com\sysvol\lvolk.com\scripts\setproxy.bat"

# reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "ProxyEnable" /t REG_DWORD /d 1 /f

New-ItemProperty -ErrorAction Stop `
-path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
-Name 'ProxyEnable' `
-Type 'Dword' `
-value 1 `
-Force `
-Confirm:$false

### Set Proxy Server
# reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "ProxyServer" /t REG_SZ /d "10.199.0.19:3128" /f

New-ItemProperty -ErrorAction Stop `
-path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' `
-Name 'ProxyServer' `
-Type 'String' `
-value $ProxyServer `
-Force `
-Confirm:$false