# Input bindings are passed in via param block.
param($Timer)
Import-Module Az.Accounts
Import-Module Az.Aks
Import-Module Az.Resources
Import-Module Az.Compute
Import-Module Az.Network
# Get the current universal time in the default string format.
$currentUTCtime = Get-Date -Date (Get-Date).ToUniversalTime() -f s 
$time = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($currentUTCtime, "UTC", "Eastern Standard Time")

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

Write-Output "Current Time is: $($time)"

$resources = Get-AzResource -TagName 'AutoStop' -TagValue 'True'

foreach($resource in $resources)
{
    Write-Output "Resource Name: $($resource.name)"
    switch($resource.ResourceType){
        "Microsoft.Compute/virtualMachines" {
            Stop-AzVM -Name $resource.name -ResourceGroupName $resource.ResourceGroupName -Force -Confirm:$false -AsJob
        }<#
        "Microsoft.ContainerService/managedClusters" {
            Stop-AzAksCluster -Name $resource.name -ResourceGroupName $resource.ResourceGroupName -Confirm:$false -AsJob
        }#>
        "Microsoft.Compute/virtualMachineScaleSets" {
            Stop-AzVmss -VMScaleSetName $resource.name -ResourceGroupName $resource.ResourceGroupName -Force -Confirm:$false -AsJob
        }
        "Microsoft.Network/azureFirewalls" {
            #Remove-AzFirewall -Name $resource.name -ResourceGroupName $resource.ResourceGroupName -Force -Confirm:$false -AsJob
            $firewall = Get-AzFirewall -Name $resource.Id.Split("/")[8] -ResourceGroupName $resource.Id.Split("/")[4]
            $firewall.Deallocate()
            Set-AzFirewall -AzureFirewall $firewall -AsJob
        }
        "Microsoft.DBforMySQL/flexibleServers" {
            Stop-AzMySqlFlexibleServer -Name $resource.name -ResourceGroupName $resource.ResourceGroupName -Confirm:$false -AsJob
        }
        default {
            Write-Output "Resource: $($resource.name) of Type: $($resource.ResourceType) not configured for start."
        }
    }
}
Get-Job | Wait-Job

Write-Output "Complete"
