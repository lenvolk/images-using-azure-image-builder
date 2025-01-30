# Input bindings are passed in via param block.
param($Timer)
Import-Module Az.Accounts
Import-Module Az.Aks
Import-Module Az.Resources
Import-Module Az.Compute
# Get the current universal time in the default string format.
$currentUTCtime = Get-Date -Date (Get-Date).ToUniversalTime() -f s 
$time = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($currentUTCtime, "UTC", "Eastern Standard Time")

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

Write-Output "Current Time is: $($time)"

$resources = Get-AzResource -TagName 'AutoStart' -TagValue 'True'

foreach($resource in $resources)
{
    Write-Output "Resource Name: $($resource.name)"
    switch($resource.ResourceType){
        "Microsoft.Compute/virtualMachines" {
            Start-AzVM -Name $resource.name -ResourceGroupName $resource.ResourceGroupName -AsJob
        }<#
        "Microsoft.ContainerService/managedClusters" {
            Start-AzAksCluster -Name $resource.name -ResourceGroupName $resource.ResourceGroupName -AsJob
        }#>
        "Microsoft.Compute/virtualMachineScaleSets" {
            Start-AzVmss -VMScaleSetName $resource.name -ResourceGroupName $resource.ResourceGroupName -AsJob
        }
        "Microsoft.DBforMySQL/flexibleServers" {
            Start-AzMySqlFlexibleServer -Name $resource.name -ResourceGroupName $resource.ResourceGroupName -AsJob
        }
        default {
            Write-Output "Resource: $($resource.name) of Type: $($resource.ResourceType) not configured for start."
        }
    }
}
Get-Job | Wait-Job

Write-Output "Complete"
