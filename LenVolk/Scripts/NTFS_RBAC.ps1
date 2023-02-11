
$ResourceGroup = "imageBuilderRG"
$SAName = "imagesapilot"
$FileShareName = "pilotshare"

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


# Get properties of the storage account for confirmation
$sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $SAName

Write-Output $sa.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties

# Set up NTFS permissions

# Get the storage key for the storage account
$keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $SAName


# Get the UNC path from the file endpoint
$UNCPath = $sa.PrimaryEndpoints.File -replace ("https://","\\")
$UNCPath = $UNCPath -replace ("/","\")

net use L: ($UNCPath + $FileShareName) $keys[0].Value /user:Azure\$SAName

# Run these from a standard command prompt
icacls L: /grant "smbadmins@lvolk.com":(OI)(CI)(IO)(F)
icacls L: /grant "wvdusers@lvolk.com":(X,RD,RA,AD)
icacls L: /grant "Creator Owner":(OI)(CI)(IO)(M)
icacls L: /remove "Authenticated Users"
icacls L: /remove "Builtin\Users"

# Use this value for the FSLogix install
$UNCPath + $FileShareName
