Connect-AzAccount

$PathToExport = ""

$subs = Get-AzSubscription

$subs | ForEach-Object -Process {

    $null = Select-AzSubscription -Subscription $_ -ErrorAction Stop

    $rgs = Get-AzResourceGroup

    $arcMachines = $rgs | ForEach-Object -Process { Get-AzConnectedMachine -ResourceGroupName $_.ResourceGroupName }

    $machinesWithMicrosoftMonitoringAgentInstalled = $arcMachines | Where-Object -FilterScript { $_.Extensions | Where-Object -FilterScript { $_.Name -eq 'MicrosoftMonitoringAgent' } }

    $machinesWithMicrosoftMonitoringAgentInstalled | Select-Object -Property Name,ResourceGroupName,SubscriptionId | Export-Csv -Path $PathToExport
}