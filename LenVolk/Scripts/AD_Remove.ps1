########## Remove from AD and add to workgroup

Param (
    [string]$user,
    [string]$pass
)


$securePass = ConvertTo-SecureString $pass -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePass)
Remove-Computer -Credential $cred -Force -Verbose
Restart-Computer -Force

# # PartOfDomain (boolean Property)
# (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
 
# # Workgroup (string Property)
# (Get-WmiObject -Class Win32_ComputerSystem).Workgroup

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