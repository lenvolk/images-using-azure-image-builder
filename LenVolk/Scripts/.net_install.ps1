#Go to the following registry key:
# HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU In the right-pane
# if the value named UseWUServer exists, set its data to 0



$WinstationsKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
$name = 'UseWUServer'
if ((Get-ItemProperty $WinstationsKey).PSObject.Properties.Name -contains $name) {
     Write-Output "updating regkey to update .net"
     New-ItemProperty -Path $WinstationsKey -Name $name -ErrorAction:SilentlyContinue -PropertyType:dword -Value 0 -Force
}
else {
    Write-Output "***** regkey name: $name not found, you can update .net"
}