#Ref https://github.com/JanneMattila/some-questions-and-some-answers/blob/master/q%26a/scan-private-endpoint-connections.ps1

class PrivateEndpointConnectionData {
    [string] $SubscriptionName
    [string] $SubscriptionID
    [string] $ResourceGroupName
    [string] $Name
    [string] $Type
    [string] $TargetResourceId
    [string] $TargetSubscription
    [string] $Description
    [string] $Status
    [boolean] $IsExternal
}

$privateEndpointConnections = New-Object System.Collections.ArrayList

$subscriptions = [array](Get-AzSubscription)

$subscriptionIds = $subscriptions.Id

Write-Host "Found $($subscriptions.length) subscriptions"

for ($i = 0; $i -lt $subscriptions.length; $i++) {
    $subscription = $subscriptions[$i]
    Select-AzSubscription -SubscriptionObject $subscription | Out-Null
    Write-Host "Processing subscription $($i + 1) / $($subscriptions.length) - $($subscription.name)"
  
    $resources = Get-AzResource
    Write-Host "Found $($resources.length) resources in subscription $($subscription.name)"

    for ($j = 0; $j -lt $resources.length; $j++) {
        $resource = $resources[$j]
        Write-Host "Processing resource $($j + 1) / $($resources.length) - $($resource.Name) - $($resource.Type)"

        $pec = [array](Get-AzPrivateEndpointConnection -PrivateLinkResourceId $resource.Id -ErrorAction SilentlyContinue)
        for ($k = 0; $k -lt $pec.Count; $k++) {
            $p = $pec[$k]

            $targetSubscription = $p.PrivateEndpoint.Id.Split("/")[2]

            $pecData = [PrivateEndpointConnectionData]::new()
            $pecData.SubscriptionName = $subscription.Name
            $pecData.SubscriptionID = $subscription.Id
            $pecData.ResourceGroupName = $resource.ResourceGroupName
            $pecData.Name = $resource.Name
            $pecData.Type = $resource.Type
            $pecData.TargetResourceId = $p.PrivateEndpoint.Id
            $pecData.TargetSubscription = $targetSubscription
            $pecData.Description = $p.PrivateLinkServiceConnectionState.Description
            $pecData.Status = $p.PrivateLinkServiceConnectionState.Status
            $pecData.IsExternal = $subscriptionIds.Contains($targetSubscription) -eq $false

            $privateEndpointConnections.Add($pecData) | Out-Null
        }
    }
}

$privateEndpointConnections | Format-Table
$privateEndpointConnections | Export-CSV "private-endpoints.csv" -Delimiter ';' -Force

Start-Process "private-endpoints.csv"