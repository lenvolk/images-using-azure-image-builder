# Specify the name of your user-assigned managed identity
$identityName = "ToolsMSI"

# Specify the name of the resource group where the managed identity exists
$resourceGroupName = "Bastion"

# Specify the subscription ID
$subscriptionId = "c29da00a-953c-4188-894e-70657319863a"

# Set the Azure context to the specified subscription (optional, but good practice if you have multiple subscriptions)
Set-AzContext -SubscriptionId $subscriptionId

# Get the user-assigned managed identity
$ManagedIdentityResourceId = (Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $identityName).Id




# --- Parameters for the Scope ---
$subscriptionId = "c29da00a-953c-4188-894e-70657319863a"
$resourceGroupName = "ShareX"
$storageAccountName = "sharexvolkbike"
# --- End of Scope Parameters ---


# Define the role name
$roleDefinitionName = "Storage Blob Data Reader"

# Construct the scope string dynamically
$scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"

# Create the role assignment
New-AzRoleAssignment -ObjectId $ManagedIdentityResourceId -RoleDefinitionName $roleDefinitionName -Scope $scope

Write-Host "Role '$roleDefinitionName' assigned to managed identity at scope '$scope'."
