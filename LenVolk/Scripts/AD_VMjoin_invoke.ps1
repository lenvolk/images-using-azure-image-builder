
# REF: https://learn.microsoft.com/en-us/powershell/module/az.compute/set-azvmaddomainextension?view=azps-9.2.0&viewFallbackFrom=azps-4.4.0
# Logs: C:\WindowsAzure\Logs\Plugins
#       C:\Packages\Plugins
# From PS: net use \\dc1.lvolk.com\ipc$ /u:lvolk\lv <mypassword>


$extensionName = 'lvolkdomainjoin'
$DomainName = 'lvolk.com'
$OUPath = 'OU=PoolHostPool,OU=AVD,DC=lvolk,DC=com'
$VMName = 'avd-win11-0'
$credential = Get-Credential 'lv@lvolk.com'
$VMRG = 'imageBuilderRG'

$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows"} 


#Set-AzVMADDomainExtension -Name $extensionName -DomainName $DomainName -OUPath $OUPath  -VMName $VMName -Credential $credential -ResourceGroupName $ResourceGroupName -JoinOption 0x00000003 -Restart -Verbose

$RunningVMs | ForEach-Object -Parallel {
    Set-AzVMADDomainExtension `
        -Name $using:extensionName `
        -DomainName $using:DomainName `
        -OUPath $using:OUPath `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -Credential $using:credential `
        -JoinOption 0x00000003 -Restart -Verbose

}
#ARM domain join
# https://learn.microsoft.com/en-us/samples/azure/azure-quickstart-templates/vm-domain-join-existing/