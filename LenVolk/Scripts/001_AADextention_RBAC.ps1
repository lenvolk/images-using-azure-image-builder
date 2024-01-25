# Azure AD Join domain extension
$vmName = "AADNative-0"
$ResourceGroup = "AVD_AADNative"
$location = "eastus2"
$hostpoolname = "AADNativeHP"

###################################
# Access Microsoft Entra joined VMs https://learn.microsoft.com/en-us/azure/virtual-desktop/azure-ad-joined-session-hosts
# https://www.youtube.com/watch?v=n_7nZFxhobc
# dsregcmd /status  (AzureAdPrt: YES)
# RDP to EntraID joined VM https://learn.microsoft.com/en-us/entra/identity/devices/howto-vm-sign-in-azure-ad-windows#log-in-using-passwordless-authentication-with-microsoft-entra-id
###################################
Install-Module -Name Az.DesktopVirtualization
Import-Module -Name Az.DesktopVirtualization
Get-AzWvdHostPool -ResourceGroupName $ResourceGroup -Name $hostpoolname

$myArmDAG = Get-AzWvdHostPool -ResourceGroupName $ResourceGroup -Name $hostpoolname

$properties = "targetisaadjoined:i:1"

$myArmDAG.CustomRdpProperty += $properties

Update-AzWvdHostPool -ResourceGroupName $ResourceGroup  -Name $hostpoolname -CustomRdpProperty $myArmDAG.CustomRdpProperty

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

# to validate run dsregcmd /status

################################
# Azure AD VM update DNS Suffix
################################
$DnsSufix = "lvolk.com"
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -Parameter @{DnsSufix = $using:DnsSufix} `
        -ScriptPath './DNS_suffix.ps1'
}


################################
#    To Add RBAC to RG         #
################################
$GroupId = (Get-AzADGroup -DisplayName "WVDUsers").id
$RoleName = (Get-AzRoleDefinition -Name "Virtual Machine User Login").name

New-AzRoleAssignment -ObjectId $GroupId `
-RoleDefinitionName $RoleName `
-ResourceGroupName $ResourceGroup
#
$GroupId = (Get-AzADGroup -DisplayName "GlobAdmin").id
$RoleName = (Get-AzRoleDefinition -Name "Virtual Machine Administrator Login").name

New-AzRoleAssignment -ObjectId $GroupId `
-RoleDefinitionName $RoleName `
-ResourceGroupName $ResourceGroup
#

$GroupId = (Get-AzADGroup -DisplayName "WVDUsers").id
$RoleName = (Get-AzRoleDefinition -Name "Desktop Virtualization Power On Contributor").name

New-AzRoleAssignment -ObjectId $GroupId `
-RoleDefinitionName $RoleName `
-ResourceGroupName $ResourceGroup

# Share Level Permissions: https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-assign-permissions?tabs=azure-powershell#share-level-permissions-for-all-authenticated-identities
# $defaultPermission = "StorageFileDataSmbShareContributor" # Set the default permission of your choice
# $account = Set-AzStorageAccount -ResourceGroupName $ResourceGroup -AccountName "imagesapilot" -DefaultSharePermission $defaultPermission
# $account.AzureFilesIdentityBasedAuth
# For SA domain joined SMB RBAC

$GroupId = (Get-AzADGroup -DisplayName "WVDUsers").id
$RoleName = (Get-AzRoleDefinition -Name "Storage File Data SMB Share Contributor").name

New-AzRoleAssignment -ObjectId $GroupId `
-RoleDefinitionName $RoleName `
-ResourceGroupName $ResourceGroup
#
$GroupId = (Get-AzADGroup -DisplayName "SMBAdmins").id
$RoleName = (Get-AzRoleDefinition -Name "Storage File Data SMB Share Elevated Contributor").name

New-AzRoleAssignment -ObjectId $GroupId `
-RoleDefinitionName $RoleName `
-ResourceGroupName $ResourceGroup

#!!!SA to AAD ref docs  (fslogix_regkey_AADSA.ps1)
# Create SA          https://learn.microsoft.com/en-us/azure/virtual-desktop/create-profile-container-azure-ad
# Enable AD Kerberos https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-azure-active-directory-enable#enable-azure-ad-kerberos-authentication-for-hybrid-user-accounts-preview
# Run from on-prem AD
# $domainInformation = Get-ADDomain 
# $domainGuid = $domainInformation.ObjectGUID.ToString() 
# $domainName = $domainInformation.DnsRoot
# !!! at the AAD VM run:
#     reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters /v CloudKerberosTicketRetrievalEnabled /t REG_DWORD /d 1 /f
##########################################
# From AAD vm to SSO on-prem share 
# make sure vnet DNS only has IP of on-prem DNS server/s (no azure wired ip 168.63.129.16)
# run example 1 from on-prem DC
# https://learn.microsoft.com/en-us/azure/active-directory/authentication/howto-authentication-passwordless-security-key-on-premises#example-1-prompt-for-all-credentials