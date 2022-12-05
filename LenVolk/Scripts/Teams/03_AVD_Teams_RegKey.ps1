

#Set Office RedirXMLSourceFolder
# $RedirXML = "\\lvolklab01.file.core.windows.net\labshare\FSLogixRules"
# $RedirXML = "\\" + $RedirXML.replace(" ", "")
New-ItemProperty -ErrorAction Stop `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "RedirXMLSourceFolder" `
    -PropertyType Multistring `
    -Value "$RedirXML" `
    -Force `
    -Confirm:$false


if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Teams")) {
    New-Item -ErrorAction Stop -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Force 
}

# Set the Teams Registry key
New-ItemProperty -ErrorAction Stop `
    -Path "HKLM:\SOFTWARE\Microsoft\Teams" `
    -Name "IsWVDEnvironment" `
    -Value "1" -PropertyType DWORD `
    -Force `
    -Confirm:$false