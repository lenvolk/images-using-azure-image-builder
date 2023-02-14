########## Remove from AD and add to workgroup
# $cred = Get-Credential lvolk\lv
Param (
    [string]$user,
    [string]$pass
)


$instance = Get-CimInstance -ComputerName $env:computername  -ClassName 'Win32_ComputerSystem'
$invCimParams = @{
    MethodName = 'UnjoinDomainOrWorkGroup'
    Arguments = @{ FUnjoinOptions=0;Username="$env:computername\"+"$user";Password=$pass }
}
$instance | Invoke-CimMethod @invCimParams

if((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain -eq $False) {
    Add-Content -LiteralPath C:\VMState.log "Now a part of WorkGruop"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "$env:computername Now a part of WorkGruop"
         Restart-Computer -Force
}
else {
    Add-Content -LiteralPath C:\VMState.log "OS is domainjoined"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "$env:computername is domainjoined"
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