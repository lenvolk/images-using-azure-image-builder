
# REF: https://learn.microsoft.com/en-us/powershell/module/az.compute/set-azvmaddomainextension?view=azps-9.2.0&viewFallbackFrom=azps-4.4.0
# Logs: C:\WindowsAzure\Logs\Plugins
#       C:\Packages\Plugins
# From PS: net use \\dc1.lvolk.com\ipc$ /u:lvolk\lv <mypassword>

# $DomainName = "lvolk.com"
# $OUPath = "OU=PoolHostPool,OU=AVD,DC=lvolk,DC=com"
# $credential = Get-Credential lvolk\lv

Param (
    [string]$DomainName,
    [string]$OUPath,
    [string]$user,
    [string]$pass
)

$securePass = ConvertTo-SecureString $pass -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($user, $securePass)
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
# Add-LocalGroupMember -Group "Administrators" -Member "lvolk\VMAdmins"
Restart-Computer -Force
}

catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error adding VM to domain: $ErrorMessage"
    Write-Output "***** Error adding VM to domain: $ErrorMessage"
}

