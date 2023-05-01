
Param (
    [string]$ProxyServer
)

# $ProxyServer = "10.199.0.19:3128"

New-ItemProperty -ErrorAction Stop `
-path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
-Name 'ProxyEnable' `
-Type 'Dword' `
-value 1 `
-Force `
-Confirm:$false


New-ItemProperty -ErrorAction Stop `
-path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' `
-Name 'ProxyServer' `
-Type 'String' `
-value $ProxyServer `
-Force `
-Confirm:$false