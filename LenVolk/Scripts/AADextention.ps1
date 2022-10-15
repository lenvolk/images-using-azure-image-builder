
Param (
    [string]$ResourceGroup,
    [string]$location
)

$VmName = $env:computername | Select-Object


Azure AD Join domain extension
$domainJoinName = "AADLoginForWindows"
$domainJoinType = "AADLoginForWindows"
$domainJoinPublisher = "Microsoft.Azure.ActiveDirectory"
$domainJoinVersion   = "1.0"

Set-AzVMExtension -VmName $VmName -ResourceGroupName $ResourceGroup -Location $location -TypeHandlerVersion $domainJoinVersion -Publisher $domainJoinPublisher -ExtensionType $domainJoinType -Name $domainJoinName

# mkdir -Path c:\ImageBuilder -name $VmName -erroraction silentlycontinue
# mkdir -Path c:\ImageBuilder -name $ResourceGroup -erroraction silentlycontinue
# mkdir -Path c:\ImageBuilder -name $location -erroraction silentlycontinue
# $ResourceGroup | Out-File -FilePath c:\ImageBuilder\$VmName.txt -Append
# $VmName | Out-File -FilePath c:\ImageBuilder\$VmName.txt -Append
# $location | Out-File -FilePath c:\ImageBuilder\$VmName.txt -Append
