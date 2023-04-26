
Param (
    [string]$ProxyServer
)


New-ItemProperty -ErrorAction Stop `
-path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' `
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