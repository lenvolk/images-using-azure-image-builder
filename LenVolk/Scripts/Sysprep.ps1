<#
.SYNOPSIS
    Used as a custom script extension for running Sysprep.ext on Windows VM's in Azure
.DESCRIPTION
    This Custom Script Extension is used to run Sysprep on a VM to prepare it for imaging.
    /mode:vm is used to speed up first boot on VM's by skipping hardware detection.
    Remove "/mode:vm" if the image will be deployed to different VM types then the source VM.
    More info here: https://www.ciraltos.com/please-wait-for-the-windows-modules-installer/

.NOTES
## https://learn.microsoft.com/en-us/azure/virtual-desktop/set-up-golden-image#other-recommendations
## https://learn.microsoft.com/en-us/azure/virtual-machines/windows/upload-generalized-managed?toc=%252fazure%252fvirtual-machines%252fwindows%252ftoc.json#generalize-the-source-vm-by-using-sysprep   
## (before running sysprep Delete the panther directory (C:\Windows\Panther))

.LINK

#>


#Script to run Sysprep on a VM
#Logging is handy when you need it!
if ((test-path c:\logfiles) -eq $false) {
    new-item -ItemType Directory -path 'c:\' -name 'logfiles' | Out-Null
} 
$logFile = "c:\logfiles\" + (get-date -format 'yyyyMMdd') + '_softwareinstall.log'

# Logging function
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}

# Delete the panther directory (C:\Windows\Panther).

try{
    write-output "Deleting Panther foleder"
    Remove-Item C:\Windows\Panther -Recurse -Force -Verbose
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error Deleting Panther folder: $ErrorMessage"
}

# Removing AVD RegKey
$CheckRegistry = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

if ($CheckRegistry)
{
Remove-Item –Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent\" –Recurse -ErrorAction SilentlyContinue
Remove-Item –Path "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader\" –Recurse -ErrorAction SilentlyContinue

}
else
{
    Write-Log -Message "VM was not registered with AVD Host Pool. Nothing to do"
}

#Run Sysprep
try{
    write-output "Sysprep Starting"
    Start-Process -filepath 'c:\Windows\system32\sysprep\sysprep.exe' -ErrorAction Stop -ArgumentList '/generalize', '/oobe', '/mode:vm', '/shutdown'
}

catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error running Sysprep: $ErrorMessage"
}