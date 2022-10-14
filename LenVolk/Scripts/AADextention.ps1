
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

mkdir c:\ImageBuilder
echo (Get-Date)  > c:\ImageBuilder\Timestamp.txt
echo (Get-Date) | Out-File -FilePath c:\ImageBuilder\Timestamp.txt -Append
$resourceGroupName | Out-File -FilePath c:\ImageBuilder\Timestamp.txt -Append
$vmName | Out-File -FilePath c:\ImageBuilder\Timestamp.txt -Append

# Azure AD Join domain extension
# $domainJoinName = "AADLoginForWindows"
# $domainJoinType = "AADLoginForWindows"
# $domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
# $domainJoinVersion   = "1.0"

# Set-AzVMExtension -VMName $vmName -ResourceGroupName $resourceGroupName -Location $location -TypeHandlerVersion $domainJoinVersion -Publisher $domainJoinPublisher -ExtensionType $domainJoinType -Name $domainJoinName
