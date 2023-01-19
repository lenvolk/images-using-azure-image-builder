# Azure AD Join domain extension
$vmName = "ChocoWin11m365"
$ResourceGroup = "imageBuilderRG"
$location = "eastus2"



###################################
# System-assigned managed identity
###################################
$RunningVMs = (get-azvm -ResourceGroupName $ResourceGroup -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RunningVMs | ForEach-Object -Parallel {
    Update-AzVM `
        -ResourceGroupName $_.ResourceGroupName `
        -VM $_ `
        -IdentityType SystemAssigned
}
# To remove identity
# Update-AzVm -ResourceGroupName $ResourceGroup -VM $vm -IdentityType None 

# 
################################
# Azure AD Join domain extension
################################
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


################################
#    To Add RBAC to RG         #
################################
$GroupId = (Get-AzADGroup -DisplayName "WVDUsers").id
$RoleName = (Get-AzRoleDefinition -Name "Virtual Machine User Login").name

New-AzRoleAssignment -ObjectId $GroupId `
-RoleDefinitionName $RoleName `
-ResourceGroupName $ResourceGroup

# For SA domain joined SMB RBAC
$GroupId = (Get-AzADGroup -DisplayName "WVDUsers").id
$RoleName = (Get-AzRoleDefinition -Name "Storage File Data SMB Share Contributor").name

New-AzRoleAssignment -ObjectId $GroupId `
-RoleDefinitionName $RoleName `
-ResourceGroupName $ResourceGroup

# OR
# https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-assign-permissions?tabs=azure-powershell#share-level-permissions-for-all-authenticated-identities

# $defaultPermission = "StorageFileDataSmbShareContributor" # Set the default permission of your choice

# $account = Set-AzStorageAccount -ResourceGroupName $ResourceGroup -AccountName "imagesapilot" -DefaultSharePermission $defaultPermission

# $account.AzureFilesIdentityBasedAuth

#SA to AAD ref docs
# https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-azure-active-directory-enable?tabs=azure-portal#enable-azure-ad-kerberos-authentication-for-hybrid-user-accounts
# $domainInformation = Get-ADDomain
# $domainGuid = $domainInformation.ObjectGUID.ToString()
# $domainName = $domainInformation.DnsRoot

# https://learn.microsoft.com/en-us/azure/virtual-desktop/create-profile-container-azure-ad
# https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-enable