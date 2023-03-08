


# PS 
# $subscription = "c6aa1fdc-66a8-446e-8b37-7794cd545e44"
# Connect-AzAccount -Subscription $subscription 
# Set-AzContext -Subscription $subscription
# Disconnect-AzAccount
#
# AZ CLI
## az cloud set --name AzureUSGovernment
## az cloud set --name AzureCloud
# az login --only-show-errors -o table --query Dummy
# $subscription = "c6aa1fdc-66a8-446e-8b37-7794cd545e44"
# az account set -s $Subscription
# az logout

# Register AIB providers / check provider state
# Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages, Microsoft.Network |
#   Where-Object RegistrationState -ne Registered |
#   Register-AzResourceProvider
# OR you can run Invoke-AIBProviderCheck

# Install Azure CLI 
# $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

# Azure Az module
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
#
#
# Install-Module Az.ImageBuilder.Tools
# Install-Module -Name Az.ImageBuilder -RequiredVersion 0.1.2
# PS 7 
# iex "&amp; { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"


$aibRG = "imageBuilderRG"
$subscription = "c6aa1fdc-66a8-446e-8b37-7794cd545e44"
$VM_User = "aibadmin"
$WinVM_Password = "P@ssw0rdP@ssw0rd"
$location = "eastus2"

$securePassword = ConvertTo-SecureString $WinVM_Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($VM_User, $securePassword)