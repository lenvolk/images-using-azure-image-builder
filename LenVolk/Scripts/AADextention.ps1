# Azure AD Join domain extension
$vmName = "ChocoWin11m365"
$ResourceGroup = "imageBuilderRG"
$location = "eastus2"


# system-assigned managed identity
$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RunningVMs | ForEach-Object -Parallel {
    Update-AzVM `
        -ResourceGroupName $_.ResourceGroupName `
        -VM $_ `
        -IdentityType SystemAssigned
}
# Update-AzVm -ResourceGroupName $ResourceGroup -VM $vm -IdentityType None  # to remove identity

# Azure AD Join domain extension
$domainJoinName = "AADLoginForWindows"
$domainJoinType = "AADLoginForWindows"
$domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
$domainJoinVersion   = "1.0"

$RunningVMs | ForEach-Object -Parallel {
    Set-AzVMExtension `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -Location $_.Location `
        -TypeHandlerVersion $using:domainJoinVersion `
        -Publisher $using:domainJoinPublisher `
        -ExtensionType $using:domainJoinType `
        -Name $using:domainJoinName
}

$GroupId = (Get-AzADGroup -DisplayName "WVDUsers").id
$RoleName = (Get-AzRoleDefinition -Name "Virtual Machine User Login").name

New-AzRoleAssignment -ObjectId $GroupId `
-RoleDefinitionName $RoleName `
-ResourceGroupName $ResourceGroup