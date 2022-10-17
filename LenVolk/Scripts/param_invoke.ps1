
Param (
    [string]$ResourceGroup,
    [string]$location
)

$VmName = $env:computername | Select-Object


mkdir -Path c:\ImageBuilder -name $VmName -erroraction silentlycontinue
mkdir -Path c:\ImageBuilder -name $ResourceGroup -erroraction silentlycontinue
mkdir -Path c:\ImageBuilder -name $location -erroraction silentlycontinue
$ResourceGroup | Out-File -FilePath c:\ImageBuilder\$VmName.txt -Append
$VmName | Out-File -FilePath c:\ImageBuilder\$VmName.txt -Append
$location | Out-File -FilePath c:\ImageBuilder\$VmName.txt -Append
