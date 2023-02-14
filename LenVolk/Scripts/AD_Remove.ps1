########## Remove from AD and add to workgroup
# $cred = Get-Credential lvolk\lv
Param (
    [string]$user,
    [string]$pass
)


$securePass = ConvertTo-SecureString $pass -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePass)
Remove-Computer -Credential $cred -Force -Verbose

if((Get-WmiObject -Class Win32_ComputerSystem).Workgroup -eq $True) {
    Add-Content -LiteralPath C:\VMState.log "Now a part of WorkGruop"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "Now a part of WorkGruop"
        Restart-Computer -Force
}
else {
    Add-Content -LiteralPath C:\VMState.log "OS is domainjoined"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "OS is domainjoined"
}

### REF
#
# sysdm.cpl
# Computer Name tab
# Change button
# Member of: Workgroup option button & enter WORKGROUP in the text box
#
# # PartOfDomain (boolean Property)
# (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
 
# # Workgroup (string Property)
# (Get-WmiObject -Class Win32_ComputerSystem).Workgroup