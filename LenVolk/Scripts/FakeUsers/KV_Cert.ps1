# Variables
$resourceGroupName = "KV-Infra"
$appServiceName = "YourAppServiceName"
$keyVaultName = "kvinfravolk01"
$certificateName = "appsrvcert01"
$subscriptionId = "4f70665a-02a0-48a0-a949-f3f645294566"
 
# Login to Azure
Connect-AzAccount
 
# Set the subscription context
Set-AzContext -SubscriptionId $subscriptionId
 
# Get the Key Vault
$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $keyVaultName
 
# Get the App Service
$appService = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $appServiceName
 
# Get the Key Vault certificate
$certificate = Get-AzKeyVaultCertificate -VaultName $keyVaultName -Name $certificateName
 
# Assign the Key Vault Certificate to the App Service
New-AzWebAppKeyVaultCertificate -ResourceGroupName $resourceGroupName -WebAppName $appServiceName -KeyVaultId $keyVault.ResourceId -KeyVaultSecretName $certificateName
 
# Assign the necessary RBAC role to the App Service to access the Key Vault
$roleAssignment = New-AzRoleAssignment -ObjectId $appService.Identity.PrincipalId -RoleDefinitionName "Key Vault Secrets User" -Scope $keyVault.ResourceId
 
Write-Output "Certificate has been configured for the App Service with RBAC."