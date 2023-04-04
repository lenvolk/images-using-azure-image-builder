
[CmdletBinding()]

Param($SubscriptionId, $Path)

$null = Select-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop

$subLevelRbacRoles = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId" -IncludeClassicAdministrators

$rgs = Get-AzResourceGroup -ErrorAction Stop

$rgLevelRbacRoles = $rgs | ForEach-Object -Process { Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId/resourceGroups/$($_.ResourceGroupName)" -IncludeClassicAdministrators }

$resources = Get-AzResource -ErrorAction Stop

$resLevelRbacRoles = $resources | ForEach-Object -Process { Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId/resourceGroups/$($_.ResourceGroupName)/providers/$($_.ResourceType)/$($_.ResourceName)" -IncludeClassicAdministrators }

$allRbacRoles = $subLevelRbacRoles + $rgLevelRbacRoles + $resLevelRbacRoles

$allRbacRoles | Select-Object -Property RoleDefinitionName, PrincipalName, Scope | Sort-Object -Property Scope

$allRbacRoles | Export-Csv -Path $Path -Force -NoTypeInformation
