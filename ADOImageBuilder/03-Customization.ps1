param (
    [bool]$choclatey,
    [bool]$winget
)

write-host "choclatey"
write-host $choclatey
write-host "winget"
write-host $winget

##################################################
# Choco
##################################################
if ($choclatey)
{
    Write-Host "Installing Choclatey packages"
    $ResourceGroup = 'ImageRefRG'
    $RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
    # (Get-Command ./AADextention.ps1).Parameters
    $RunningVMs | ForEach-Object -Parallel {
        Invoke-AzVMRunCommand `
            -ResourceGroupName $_.ResourceGroupName `
            -VMName $_.Name `
            -CommandId 'RunPowerShellScript' `
            -ScriptPath '.\Choco.ps1'
    }
}

##################################################
# Winget
##################################################
if ($winget)
{
    Write-Host "Installing Winget packages"
    $ResourceGroup = 'ImageRefRG'
    $RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
    # (Get-Command ./AADextention.ps1).Parameters
    $RunningVMs | ForEach-Object -Parallel {
        Invoke-AzVMRunCommand `
            -ResourceGroupName $_.ResourceGroupName `
            -VMName $_.Name `
            -CommandId 'RunPowerShellScript' `
            -ScriptPath '.\Winget.ps1'
    }
}

##################################################
# Add_2_Domain
##################################################
# $DomainName = 'volk.bike'
# $OUPath = 'OU=PoolHostPool,DC=volk,DC=bike'
# $user = 'volk\lv'
# $pass = 'xxxxx'

# $ResourceGroup = 'ImageRefRG'
# $RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# # (Get-Command ./AADextention.ps1).Parameters
# $RunningVMs | ForEach-Object -Parallel {
#     Invoke-AzVMRunCommand `
#         -ResourceGroupName $_.ResourceGroupName `
#         -VMName $_.Name `
#         -CommandId 'RunPowerShellScript' `
#         -Parameter @{DomainName = $using:DomainName;OUPath = $using:OUPath;user = $using:user;pass = $using:pass} `
#         -ScriptPath '.\AD_Add_PSscript.ps1'
# }

##################################################
# AD_Remove
##################################################
# $user = 'aibadmin'
# $pass = 'P@ssw0rdP@ssw0rd'

# $ResourceGroup = 'ImageRefRG'
# $RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# $RunningVMs | ForEach-Object -Parallel {
#     Invoke-AzVMRunCommand `
#         -ResourceGroupName $_.ResourceGroupName `
#         -VMName $_.Name `
#         -CommandId 'RunPowerShellScript' `
#         -Parameter @{user = $using:user;pass = $using:pass} `
#         -ScriptPath '.\AD_Remove.ps1'
# }