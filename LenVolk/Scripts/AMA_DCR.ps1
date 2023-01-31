$dcrname = 'Microsoft-VMInsights-Health-eastus'
$rgname = 'lab1hprg'


# New-Item -Path . -Name dcrResources.txt -ItemType "file" $dcrname = 'arcdcr'
$resources = (Get-AzDataCollectionRuleAssociation -ResourceGroupName $rgname -RuleName $dcrname).Id
$resources | ForEach-Object {
    Write-Host $_.Split("/")[3] $_.Split("/")[8]
    $RGName = $_.Split("/")[3]
    $vmName = $_.Split("/")[8]
    #Add-Content -Path .\dcrResources.txt -Value "$RGName $vmName"
}