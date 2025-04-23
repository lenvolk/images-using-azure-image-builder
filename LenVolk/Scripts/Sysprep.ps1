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
## for win11 issue https://internal.evergreen.microsoft.com/en-us/topic/c94bb007-e8cc-6735-4643-7b17805fbcaa

.LINK

#>

# Script to run Sysprep on a VM
#Logging is handy when you need it!
if ((test-path c:\logfiles) -eq $false) {
    new-item -ItemType Directory -path 'c:\' -name 'logfiles' | Out-Null
} 
$logFile = "c:\logfiles\" + (get-date -format 'yyyyMMdd') + '_softwareinstall.log'

# Logging function
function Write-Log {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$message
    )
    "$(Get-Date -Format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}

Write-Log -Message "Starting Sysprep script execution."

# Delete the panther directory (C:\Windows\Panther).
Write-Log -Message "Attempting to delete Panther folder (C:\Windows\Panther)."
$pantherPath = "C:\Windows\Panther"
if (Test-Path $pantherPath) {
    Remove-Item $pantherPath -Recurse -Force -ErrorAction SilentlyContinue
    if ($?) {
        Write-Log -Message "Panther folder deleted successfully."
    } else {
        Write-Log -Message "Error deleting Panther folder. Error details: $($error[0])"
        # Optionally add -ErrorAction Stop above and wrap in Try/Catch if deletion failure should stop the script
    }
} else {
    Write-Log -Message "Panther folder not found. No deletion needed."
}


# Removing AVD RegKey
Write-Log -Message "Checking for AVD registry keys."
$regPathInfraAgent = "HKLM:\SOFTWARE\Microsoft\RDInfraAgent"
$regPathBootLoader = "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader"
$infraAgentExists = Test-Path $regPathInfraAgent
$bootLoaderExists = Test-Path $regPathBootLoader

if ($infraAgentExists -or $bootLoaderExists)
{
    Write-Log -Message "AVD registry keys found. Attempting removal."
    if ($infraAgentExists) {
        Remove-Item -Path $regPathInfraAgent -Recurse -Force -ErrorAction SilentlyContinue
        if ($?) { Write-Log -Message "Removed ${regPathInfraAgent}." } else { Write-Log -Message "Error removing ${regPathInfraAgent}: $($error[0])" }
    }
    if ($bootLoaderExists) {
        Remove-Item -Path $regPathBootLoader -Recurse -Force -ErrorAction SilentlyContinue
        if ($?) { Write-Log -Message "Removed ${regPathBootLoader}." } else { Write-Log -Message "Error removing ${regPathBootLoader}: $($error[0])" }
    }
}
else
{
    Write-Log -Message "AVD registry keys not found. No removal needed."
}

# Run Sysprep
Write-Log -Message "Attempting to start Sysprep."
try {
    Start-Process -FilePath 'c:\Windows\system32\sysprep\sysprep.exe' -ArgumentList '/generalize', '/oobe', '/mode:vm', '/shutdown' -Wait -PassThru -ErrorAction Stop
    Write-Log -Message "Sysprep process initiated successfully and shutdown command issued."
    # Note: Script execution will likely end here as sysprep shuts down the machine.
    # Further logging might only occur if sysprep fails before shutdown.
}
catch {
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.ScriptStackTrace
    Write-Log -Message "FATAL: Error running Sysprep. Message: $ErrorMessage. StackTrace: $StackTrace"
    # Consider exiting with a non-zero code if running in an automation pipeline
    # exit 1
}

Write-Log -Message "Sysprep script finished (or Sysprep initiated shutdown)."
