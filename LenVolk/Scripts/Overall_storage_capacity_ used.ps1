
# Install-Module -Name Az.ResourceGraph

# $query = "resources | where type == 'microsoft.compute/disks' | where subscriptionId == '4f70665a-02a0-48a0-a949-f3f645294566' | extend accountType = tostring(sku['name']) | extend diskSizeGB = toint(properties['diskSizeGB']) | summarize ProvisionedGB=sum(diskSizeGB) by accountType"

$query = @"
resources
| where type == "microsoft.compute/disks"
| where subscriptionId == "4f70665a-02a0-48a0-a949-f3f645294566"
| extend accountType = tostring(sku['name'])
| extend diskSizeGB = toint(properties['diskSizeGB'])
| summarize ProvisionedGB=sum(diskSizeGB) by accountType
"@

$results = Search-AzGraph -Query $query
$results