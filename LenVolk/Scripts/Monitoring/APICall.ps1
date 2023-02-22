https://management.azure.com//subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44/resourceGroups/Lab1MSIXHPRG/providers/Microsoft.Compute/virtualMachines/Lab1MSIX-1-0/extensions/MicrosoftMonitoringAgent?api-version=2015-06-15

$ctx = Get-AzContext

$auth = @{Authorization = "bearer $token"}

foreach ($vm in $vms) {
    Invoke-RestMethod -Uri "uri with vm name" -Method Delete -Headers $auth
}



Remove-AzOperationalInsightsDataSource -Workspace $WorkspaceName -Name $VMName