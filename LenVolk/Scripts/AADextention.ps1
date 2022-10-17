# Azure AD Join domain extension

$ResourceGroup = "imageBuilderRG"
$location = "eastus2"


$domainJoinName = "AADLoginForWindows"
$domainJoinType = "AADLoginForWindows"
$domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
$domainJoinVersion   = "1.0"

Set-AzVMExtension -VmName $VmName -ResourceGroupName $ResourceGroup -Location $location -TypeHandlerVersion $domainJoinVersion -Publisher $domainJoinPublisher -ExtensionType $domainJoinType -Name $domainJoinName


$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
# (Get-Command ./BGInfo.ps1).Parameters
$RunningVMs | ForEach-Object -Parallel {
    Set-AzVMExtension `
        -VMName $_.Name `
        -ResourceGroupName $_.ResourceGroupName
        -Name "AADLoginForWindows" `
        -Location $_.Location `
        -Publisher "Microsoft.Azure.ActiveDirectory" `
        -Type "AADLoginForWindows" `
        -TypeHandlerVersion "1.0"
}


