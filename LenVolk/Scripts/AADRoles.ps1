# First log in to Azure and get the subscription ID
Add-AzAccount

$subscriptionId = $(Get-AzContext).Subscription.Id

# Now get or create the group to assign permissions to
$DisplayName = "AVD Admins"
$MailNickName = "AVDAdmins"

# Create the group if it doesn't exist
New-AzADGroup -DisplayName $DisplayName -MailNickname $MailNickName -SecurityEnabled

# Retrieve the group ID
$aadGroupId = $(get-azadgroup -DisplayName $DisplayName).Id

# Assign the Desktop Virtualization Workspace Contributor role to the group
New-AzRoleAssignment -ObjectId $aadGroupId -RoleDefinitionName "Desktop Virtualization Workspace Contributor" -Scope "/subscriptions/$subscriptionId"