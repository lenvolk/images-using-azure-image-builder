
Param (
    [string]$ResourceGroup,
    [string]$VmName,
    [string]$location
)



mkdir -Path c:\ImageBuilder -name $VmName -erroraction silentlycontinue
$VmName  >> c:\ImageBuilder\Tst.txt
# $resourceGroupName | Out-File -FilePath c:\ImageBuilder\Timestamp.txt -Append
# $VmName | Out-File -FilePath c:\ImageBuilder\Timestamp.txt -Append
# $location | Out-File -FilePath c:\ImageBuilder\Timestamp.txt -Append

# Azure AD Join domain extension
# $domainJoinName = "AADLoginForWindows"
# $domainJoinType = "AADLoginForWindows"
# $domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
# $domainJoinVersion   = "1.0"

# Set-AzVMExtension -VmName $VmName -ResourceGroupName $resourceGroupName -Location $location -TypeHandlerVersion $domainJoinVersion -Publisher $domainJoinPublisher -ExtensionType $domainJoinType -Name $domainJoinName
