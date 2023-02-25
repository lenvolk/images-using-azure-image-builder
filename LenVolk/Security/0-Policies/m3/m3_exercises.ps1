### Create an alert for deleting Resource Groups in Azure Sentinel
# Rule query text
union AzureActivity
| sort by TimeGenerated desc 
| where OperationNameValue == "Microsoft.Resources/subscriptions/resourcegroups/delete"
| extend AccountCustomEntity = SubscriptionId
| extend HostCustomEntity = Caller
| extend IPCustomEntity = CallerIpAddress

# Log into Azure
Add-AzAccount

# Select the appropriate subscription
# Change SUB_NAME to your subscription name
Get-AzSubscription -SubscriptionName "MSDN-SUB" | Select-AzSubscription

# Create 10 Resource Groups
for($i=0;$i -lt 10; $i++){
    New-AzResourceGroup -Name "myRG$i" -Location "East US"
}

# Now delete the Resource Groups to test
for($i=0;$i -lt 10; $i++){
    Remove-AzResourceGroup -Name "myRG$i" -Force
}