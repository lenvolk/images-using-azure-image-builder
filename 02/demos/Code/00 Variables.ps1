# Ref https://powers-hell.com/2020/09/20/preparing-custom-image-templates-with-azure-image-builder-powershell/
# Install-Module -Name Az.ImageBuilder -RequiredVersion 0.1.2
#
# $subscription = "4f70665a-02a0-48a0-a949-f3f645294566"
# Connect-AzAccount -Subscription $subscription
# Disconnect-AzAccount


$aibRG = "imageBuilderRG"
$subscription = "4f70665a-02a0-48a0-a949-f3f645294566"
$VM_User = "aibadmin"
$WinVM_Password = "P@ssw0rdP@ssw0rd"
$location = "eastus2"

$securePassword = ConvertTo-SecureString $WinVM_Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($VM_User, $securePassword)