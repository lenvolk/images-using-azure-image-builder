### Create an alert for deleting Resource Groups in Azure Sentinel
# Rule query text
union AzureActivity
| sort by TimeGenerated desc 
| where OperationNameValue == "Microsoft.Resources/subscriptions/resourcegroups/delete"
| extend AccountCustomEntity = SubscriptionId
| extend HostCustomEntity = Caller
| extend IPCustomEntity = CallerIpAddress

#Log into Azure with CLI
az login
az account set --subscription "MSDN-SUB"

# Create 10 Resource Groups
for i in {0..9}
do
    az group create -n "myRG$i" -l "eastus"
done

# Now delete the Resource Groups to test
for i in {0..9}
do
    az group delete -n "myRG$i" --yes
done