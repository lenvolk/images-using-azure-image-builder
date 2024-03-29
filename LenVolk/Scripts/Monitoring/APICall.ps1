
$azContext = Get-AzContext
$subscriptionID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}


$restUri = "https://management.azure.com/subscriptions/"+$subscriptionID+"?api-version=2016-06-01"
$response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader


# https://management.azure.com//subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44/resourceGroups/Lab1MSIXHPRG/providers/Microsoft.Compute/virtualMachines/Lab1MSIX-1-0/extensions/MicrosoftMonitoringAgent?api-version=2015-06-15
#
# $restUri= "https://management.azure.com/providers/Microsoft.Management/managementGroups/$managementGroup/providers/Microsoft.Blueprint/blueprints/$blueprint/versions/"+$version+"?api-version=2018-11-01-preview"
# foreach ($vm in $vms) {
#     Invoke-RestMethod -Uri "uri with vm name" -Method Delete -Headers $auth
# }



# Remove-AzOperationalInsightsDataSource -Workspace mainlaw -Name Lab1MSIX-1-0