


$job = Start-AzPolicyComplianceScan  -ResourceGroupName "ArcBox" -AsJob
$job | Wait-Job