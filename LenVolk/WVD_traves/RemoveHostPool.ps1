
# Set the host pool variables 
$hostPoolResourceGroup = 'HostPoolRG'
$hostPoolName = 'HostPoolName'

# Get the Application Groups
$appGroups = Get-AzWvdApplicationGroup -ResourceGroupName $hostPoolResourceGroup

# Remove the Application Groups
foreach ($appGroup in $appGroups) {
    Remove-AzWvdApplicationGroup -Name $appGroup.Name -ResourceGroupName $hostPoolResourceGroup
    Write-Output "Removed: $($appGroup.name)"
}

# Remove the Host Pool
Remove-AzWvdHostPool -Name $hostPoolName -ResourceGroupName $hostPoolResourceGroup -Force:$true

# Remove the Resource Group
# View items in the Resource Group
Get-AzResource -ResourceGroupName $hostPoolResourceGroup | Select-Object Name,ResourceGroupName

# Optional, be sure nothing in the Resource Group is still in use
Remove-AzResourceGroup -Name $hostPoolResourceGroup

# View existing Resource Groups
Get-AzResourceGroup | Select-Object ResourceGroupName
