
$VMRG = 'imageBuilderRG';

$params=@{
$extensionName = 'lvolkdomainjoin';
$DomainName = 'lvolk.com';
$OUPath = 'OU=PoolHostPool,OU=AVD,DC=lvolk,DC=com';
$VMName = 'avd-win11-0';
$credential = Get-Credential 'lv@lvolk.com'
}

$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows"} 

$RunningVMs | ForEach-Object -Parallel {
    Set-AzVMADDomainExtension `
        -Parameter $params
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -JoinOption 0x00000003 -Restart -Verbose
