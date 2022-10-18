# Azure AD Join domain extension
$vmName = "ChocoWin11m365"
$ResourceGroup = "imageBuilderRG"
$location = "eastus2"


$domainJoinName = "AADLoginForWindows"
$domainJoinType = "AADLoginForWindows"
$domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
$domainJoinVersion   = "1.0"

$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 


# system-assigned managed identity
$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $vmName
Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm -IdentityType SystemAssigned
# Update-AzVm -ResourceGroupName myResourceGroup -VM $vm -IdentityType None  # to remove identity

# Azure AD Join domain extension
$domainJoinName = "AADLoginForWindows"
$domainJoinType = "AADLoginForWindows"
$domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
$domainJoinVersion   = "1.0"

Set-AzVMExtension -VMName $vmName -ResourceGroupName $ResourceGroup -Location $location -TypeHandlerVersion $domainJoinVersion -Publisher $domainJoinPublisher -ExtensionType $domainJoinType -Name $domainJoinName

az role assignment create --assignee $imgBuilderCliId --role $imageRoleDefName --scope $RGScope




# (Get-Command ./BGInfo.ps1).Parameters
# $RunningVMs | ForEach-Object -Parallel {
#     Set-AzVMExtension `
#         -VMName $_.Name `
#         -ResourceGroupName $_.ResourceGroupName
#         -Name "AADLoginForWindows" `
#         -Location $_.Location `
#         -Publisher "Microsoft.Azure.ActiveDirectory" `
#         -Type "AADLoginForWindows" `
#         -TypeHandlerVersion "1.0"
# }
