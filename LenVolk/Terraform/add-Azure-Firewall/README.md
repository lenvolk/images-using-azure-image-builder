# Azure Firewall

Hi. So you've decided to deploy the Azure Firewall in your AVD environment. That's cool! I wanted to take a moment and point out that the Azure Firewall is an expensive service to deploy. It clocks in at roughly $1.25/hour when you have it running. Please take that into consideration before deploying the firewall and factor it into how long you want to leave it running.

Thanks!

## Rules Flow
[doc](https://learn.microsoft.com/en-us/azure/firewall/rule-processing)

## AVD Rules required
[doc](https://learn.microsoft.com/en-us/azure/firewall/protect-azure-virtual-desktop?tabs=azure#create-network-rules)


[FW Workbook](https://github.com/Azure/Azure-Network-Security/tree/master/Azure%20Firewall/Workbook%20-%20Azure%20Firewall%20Monitor%20Workbook)

## Save $$ and deallocate AzFW
```powershell
# Stop an existing firewall
$azfw = Get-AzFirewall -Name "avd-FW-eastus" -ResourceGroupName $hub_vnet_resource_group
$azfw.Deallocate()
Set-AzFirewall -AzureFirewall $azfw

# Start the firewall
$azfw = Get-AzFirewall -Name "avd-FW-eastus" -ResourceGroupName $hub_vnet_resource_group
$vnet = Get-AzVirtualNetwork -ResourceGroupName $hub_vnet_resource_group -Name $vnetName
$publicip1 = Get-AzPublicIpAddress -Name "avd-FW-eastus" -ResourceGroupName $hub_vnet_resource_group
$azfw.Allocate($vnet,@($publicip1))
Set-AzFirewall -AzureFirewall $azfw
```
[MoreScripts](https://github.com/Azure/Azure-Network-Security)