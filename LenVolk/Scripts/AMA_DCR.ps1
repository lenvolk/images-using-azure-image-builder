$SubscriptionId = "xxxxxxxx-xxxx"
Connect-AzAccount -Subscription $SubscriptionId
Set-AzContext -Subscription $SubscriptionId
# Disconnect-AzAccount

$dcrname = 'Microsoft-VMInsights-Health-eastus'
$rgname = 'lab1hprg'


#New-Item -Path . -Name dcrResources.txt -ItemType "file"
$resources = (Get-AzDataCollectionRuleAssociation -ResourceGroupName $rgname -RuleName $dcrname).Id
$resources | ForEach-Object {
    Write-Host $_.Split("/")[3] $_.Split("/")[8]
    $RGName = $_.Split("/")[3]
    $vmName = $_.Split("/")[8]
    #Add-Content -Path .\dcrResources.txt -Value "$RGName $vmName"
}

# Check which LAW DCR is pointing to, from LAW run 
# Heartbeat | where Category == "Azure Monitor Agent" | distinct Computer

# report on LAW agent https://argonsys.com/microsoft-cloud/library/how-to-find-your-azure-log-analytics-agent-deployments-in-preparation-for-the-azure-monitor-agent/
