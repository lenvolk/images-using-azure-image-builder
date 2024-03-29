Function CreateFileShare  
{  
    Param($ShareName)

    Write-Host -ForegroundColor Green "Creating an file Share.."    
    ## Get the storage account context  
    $ctx=(Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $SAName).Context  
    ## Creates an file share  
    New-AzStorageShare -Context $ctx -Name $ShareName
}  

$ResourceGroup = "imageBuilderRG"
$SAName = "imagesaaad"
$FileShareName = "avdprofiles"

#Create AVD Profiles share
CreateFileShare $FileShareName

# SA SMB RBAC
$GroupId = (Get-AzADGroup -DisplayName "WVDUsers").id
$RoleName = (Get-AzRoleDefinition -Name "Storage File Data SMB Share Contributor").name
New-AzRoleAssignment -ObjectId $GroupId `
-RoleDefinitionName $RoleName `
-ResourceGroupName $ResourceGroup `
-ErrorAction SilentlyContinue

#
$GroupId = (Get-AzADGroup -DisplayName "SMBAdmins").id
$RoleName = (Get-AzRoleDefinition -Name "Storage File Data SMB Share Elevated Contributor").name
New-AzRoleAssignment -ObjectId $GroupId `
-RoleDefinitionName $RoleName `
-ResourceGroupName $ResourceGroup `
-ErrorAction SilentlyContinue

# Get properties of the storage account for confirmation
$sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $SAName

Write-Output $sa.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties

# Set up NTFS permissions
# https://learn.microsoft.com/en-us/azure/virtual-desktop/fslogix-profile-container-configure-azure-files-active-directory?tabs=adds#set-ntfs-permissions
# Get the storage key for the storage account
$keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $SAName


# Get the UNC path from the file endpoint
$UNCPath = $sa.PrimaryEndpoints.File -replace ("https://","\\")
$UNCPath = $UNCPath -replace ("/","\")

net use L: ($UNCPath + $FileShareName) $keys[0].Value /user:Azure\$SAName
# Run these from a standard command prompt
L:
icacls L: /inheritance:r
icacls L: /grant "avd-admins@volk.bike":(OI)(CI)(F)
icacls L: /grant "avd-users-gpr":(X,R,RD,RA,REA,AD)
icacls L: /grant "accounting-users-grp":(X,R,RD,RA,REA,AD)
icacls L: /grant "marketing-users-grp":(X,R,RD,RA,REA,AD)
icacls N: /grant "Domain Admins":(OI)(CI)(F)
icacls L: /grant "Creator Owner":(OI)(CI)(IO)(M)
icacls L: /remove "Authenticated Users"
icacls L: /remove "Builtin\Users"

# Use this value for the FSLogix user profile path
# $ProfileShare = $UNCPath + $FileShareName

# # Creating office profile share
# $FileShareName = "offcontshare"
# CreateFileShare $FileShareName
# net use M: ($UNCPath + $FileShareName) $keys[0].Value /user:Azure\$SAName
# # Run these from a standard command prompt
# cd M:
# icacls M: /inheritance:r
# icacls M: /grant "avd-admins@volk.bike":(OI)(CI)(F)
# icacls M: /grant "avd-users-gpr":(X,R,RD,RA,REA,AD)
# icacls M: /grant "Creator Owner":(OI)(CI)(IO)(M)
# icacls M: /remove "Authenticated Users"
# icacls M: /remove "Builtin\Users"

# Creating AppMasking Share AND redirection.xml
$FileShareName = "avdshares"
CreateFileShare $FileShareName

net use N: ($UNCPath + $FileShareName) $keys[0].Value /user:Azure\$SAName
# Run these from a standard command prompt
N:
icacls N: /inheritance:r
icacls N: /grant "avd-admins@volk.bike":(OI)(CI)(F)
icacls N: /grant "avd-users-gpr":(OI)(CI)(R,X)
icacls N: /grant "accounting-users-grp":(OI)(CI)(R,X)
icacls N: /grant "marketing-users-grp":(OI)(CI)(R,X)
icacls N: /grant "Creator Owner":(OI)(CI)(IO)(M)
icacls N: /grant "Domain Admins":(OI)(CI)(F)
icacls N: /remove "Authenticated Users"
icacls N: /remove "Builtin\Users"



# Net Use * /delete