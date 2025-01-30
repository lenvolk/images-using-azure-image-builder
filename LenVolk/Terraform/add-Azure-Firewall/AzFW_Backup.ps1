# Ref https://github.com/proximagr/automation/blob/master/Export%20Azure%20Firewall%20Policy%20Rules.ps1


# Authenticate to Azure
 
$subscription = "DemoSub"
Connect-AzAccount -Subscription $subscription 
az login --only-show-errors -o table --query Dummy
az account set -s $Subscription


#Provide Input. Firewall Policy Name, Firewall Policy Resource Group & Firewall Policy Rule Collection Group Name
$fpname = "avd-FW-eastus2"
$fprg = "maintenance"
$fprcgname = "avd-FW-eastus2"

$fp = Get-AzFirewallPolicy -Name $fpname -ResourceGroupName $fprg
$rcg = Get-AzFirewallPolicyRuleCollectionGroup -Name $fprcgname -AzureFirewallPolicy $fp

$returnObj = @()
foreach ($rulecol in $rcg.Properties.RuleCollection) {

foreach ($rule in $rulecol.rules)
{
$properties = [ordered]@{
    RuleCollectionName = $rulecol.Name;
    RulePriority = $rulecol.Priority;
    ActionType = $rulecol.Action.Type;
    RUleConnectionType = $rulecol.RuleCollectionType;
    Name = $rule.Name;
    protocols = $rule.protocols -join ", ";
    SourceAddresses = $rule.SourceAddresses -join ", ";
    DestinationAddresses = $rule.DestinationAddresses -join ", ";
    SourceIPGroups = $rule.SourceIPGroups -join ", ";
    DestinationIPGroups = $rule.DestinationIPGroups -join ", ";
    DestinationPorts = $rule.DestinationPorts -join ", ";
    DestinationFQDNs = $rule.DestinationFQDNs -join ", ";
}
$obj = New-Object psobject -Property $properties
$returnObj += $obj
}

#change c:\temp to the path to export the CSV
$returnObj | Export-Csv "C:\Temp\BackUP\Temp\images-using-azure-image-builder\LenVolk\Terraform\add-Azure-Firewall\rules.csv" -NoTypeInformation
}
