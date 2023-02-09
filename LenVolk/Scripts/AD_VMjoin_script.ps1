
# REF: https://learn.microsoft.com/en-us/powershell/module/az.compute/set-azvmaddomainextension?view=azps-9.2.0&viewFallbackFrom=azps-4.4.0
# Logs: C:\WindowsAzure\Logs\Plugins
#       C:\Packages\Plugins
# From PS: net use \\dc1.lvolk.com\ipc$ /u:lvolk\lv <mypassword>

# $VMRG = "imageBuilderRG"
# $DomainName = "lvolk.com"
# $OUPath = "OU=PoolHostPool,OU=AVD,DC=lvolk,DC=com"
# $credential = Get-Credential lvolk\lv

Param (
    [string]$DomainName,
    [string]$OUPath,
    [string]$credential
)
####################################
if((Test-Path c:\temp) -eq $false) {
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Create C:\temp Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
    New-Item -Path c:\temp -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "C:\temp Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "temp directory already exists"
}

####################################
$logFile = "c:\temp\" + (get-date -format 'yyyyMMdd') + '_ADJoin.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}
####################################

try {
Add-Computer -DomainName $DomainName -OUPath $OUPath -Credential $credential -Force
Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $env:computername successfully domain joined" | Out-File -Encoding utf8 $logFile -Append
Restart-Computer -Force
}

catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding VM to domain: $ErrorMessage"
    Write-Output "***** Error adding VM to domain: $ErrorMessage"
}


########## Remove from AD and add to workgroup
# $username = "domain01\admin01"
# $password = Get-Content 'C:\mysecurestring.txt' | ConvertTo-SecureString
# $cred = new-object -typename System.Management.Automation.PSCredential `
#          -argumentlist $username, $password

# Remove-Computer -UnjoinDomaincredential Domain01\Admin01 -PassThru -Verbose -Restart