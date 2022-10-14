
param (
    [string]$arg1,

    [string]$arg2,

    [string]$arg3
)


# VM Properties
$resourceGroupName = $arg1
$vmName = $arg2
$location = $arg3 

Write-Output $resourceGroupName
Write-Output $vmName
Write-Output $location


# Azure AD Join domain extension
$domainJoinName = "AADLoginForWindows"
$domainJoinType = "AADLoginForWindows"
$domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
$domainJoinVersion   = "1.0"

Set-AzVMExtension -VMName $vmName -ResourceGroupName $resourceGroupName -Location $location -TypeHandlerVersion $domainJoinVersion -Publisher $domainJoinPublisher -ExtensionType $domainJoinType -Name $domainJoinName
