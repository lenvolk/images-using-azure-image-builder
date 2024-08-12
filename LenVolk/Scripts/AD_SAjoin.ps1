# !!!  AAD SA join !!! 
# https://smbtothecloud.com/azure-ad-joined-avd-with-fslogix-aad-kerberos-authentication/
# 
# https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-azure-active-directory-enable#enable-azure-ad-kerberos-authentication-for-hybrid-user-accounts-preview
# 
# Cloud Cache https://gbbblog.azurewebsites.us/index.php/2022/02/23/spare-the-share-aadj-avd-and-fslogix-cloud-cache/
# !!!

# Download AzFilesHybrid
# https://github.com/Azure-Samples/azure-files-samples/releases


## Join the Storage Account for SMB Auth Microsoft Source:
## https://docs.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-enable

function Check-IsAdmin{

  (whoami /all | Select-String S-1-16-12288) -ne $null
}


if (Check-IsAdmin) {
#Change the execution policy to unblock importing AzFilesHybrid.psm1 module
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

# Navigate to where AzFilesHybrid is unzipped and stored and run to copy the files into your path
.\CopyToPSPath.ps1 

#Import AzFilesHybrid module
Import-Module -Name AzFilesHybrid
}
else {
  Write-Error "Script needs to be run with higher privileges"
}

#Install AZ ps module
Install-Module -Name Az -Repository PSGallery -Force

#Login with an Azure AD credential that has either storage account owner or contributor Azure role assignment
Get-AzContext #to validate if logged in

Connect-AzAccount
Get-AzSubscription
# Set subscription by Id
Set-AzContext -SubscriptionId "4f70665a-02a0-48a0-a949-f3f645294566"
# Set subscription by Name
Set-AzContext -SubscriptionName "AzIntConsumption"
# to validate
Get-AzContext

#Define parameters
$SubscriptionId = "4f70665a-02a0-48a0-a949-f3f645294566"
$ResourceGroupName = "DFS"
$StorageAccountName = "fileservervolk"

#Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionId 

# To create new SA
# $location = "eastus"
# $prefix = "volk"
# $id = Get-Random -Minimum 1000 -Maximum 9999
# $rg1 = New-AzResourceGroup -Name "$prefix-$id-1" -Location $location
# if (Get-AzStorageAccountNameAvailability -Name "$($prefix)sa$id")
# {
# #Create a new storage account
# $saAccountParameters = @{
#     Name = "$($prefix)sa$id"
#     ResourceGroupName = $rg1.ResourceGroupName
#     Location = $location
#     SkuName = "Standard_LRS"
#     AllowBlobPublicAccess = $true
# }
# $storageAccount = New-AzStorageAccount @saAccountParameters

# }
# Premium Storage - Use this for production
# $saAccountParameters = @{
#     Name = "$($prefix)sa$id"
#     ResourceGroupName = $ResourceGroupName
#     Location = $location
#     SkuName = "Premium_LRS"
#     AllowBlobPublicAccess = $true
#     Kind = "FileStorage"
# }
# $storageAccount = New-AzStorageAccount @saAccountParameters

# Register the target storage account with your active directory environment under the target OU (for example: specify the OU with Name as "UserAccounts" or DistinguishedName as "OU=UserAccounts,DC=CONTOSO,DC=COM"). 
# You can use to this PowerShell cmdlet: Get-ADOrganizationalUnit to find the Name and DistinguishedName of your target OU. If you are using the OU Name, specify it with -OrganizationalUnitName as shown below. If you are using the OU DistinguishedName, you can set it with -OrganizationalUnitDistinguishedName. You can choose to provide one of the two names to specify the target OU.
# You can choose to create the identity that represents the storage account as either a Service Logon Account or Computer Account (default parameter value), depends on the AD permission you have and preference. 
# "<ComputerAccount|ServiceLogonAccount>" # Default is set as ComputerAccount
# Run Get-Help Join-AzStorageAccountForAuth for more details on this cmdlet.


# Ref https://learn.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-enable#run-join-azstorageaccount

Join-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        #-DomainAccountType "ComputerAccount" `
        -DomainAccountType "ServiceLogonAccount" `
        -OrganizationalUnitDistinguishedName "OU=AzSA,DC=volk,DC=bike" # If you don't provide the OU name as an input parameter, the AD identity that represents the storage account is created under the root directory.

#You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD configuration with the logged on AD user. This cmdlet is supported on AzFilesHybrid v0.1.2+ version. For more details on the checks performed in this cmdlet, see Azure Files Windows troubleshooting guide.
Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose


# Confirm the feature is enabled
# Get the target storage account
$storageaccount = Get-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName

# List the directory service of the selected service account
$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions

# List the directory domain information if the storage account has enabled AD DS authentication for file shares
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties



# Mount the file share as supper user

#Define parameters
$StorageAccountName = "fileservervolk"
$ShareName = "<share-name-here>"
$StorageAccountKey = "<account-key-here>"

#  Run the code below to test the connection and mount the share
$connectTestResult = Test-NetConnection -ComputerName "$StorageAccountName.file.core.windows.net" -Port 445
if ($connectTestResult.TcpTestSucceeded)
{
  net use T: "\\$StorageAccountName.file.core.windows.net\$ShareName" /user:Azure\$StorageAccountName $StorageAccountKey
} 
else 
{
  Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN,   Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}


# Path to the file share
# Replace drive letter, storage account name and share name with your settings
# "\\<StorageAccountName>.file.core.windows.net\<ShareName>"

# Set Password to Never Expire for Domain Accounts in Windows Server
# https://www.top-password.com/blog/set-password-to-never-expire-for-domain-accounts-in-windows-server/