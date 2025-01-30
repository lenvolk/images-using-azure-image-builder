

# $avdappgrp = New-AzPolicyDefinition -ManagementGroupName "volk-SandBox" -Name "policy-deploy-diagnostics-avd-application-group" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-application-group.json
# to the current subscription
$avdappgrp = New-AzPolicyDefinition -Name "avd-application-group" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-application-group.json

$avdhp = New-AzPolicyDefinition -Name "avd-host-pool" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-host-pool.json

$avdscalplan = New-AzPolicyDefinition -Name "avd-scaling-plan" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-scaling-plan.json

$avdws = New-AzPolicyDefinition -Name "avd-workspace" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-workspace.json

$avdazfiles = New-AzPolicyDefinition -Name "avd-azure-files" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-azure-files.json

$avdnsg = New-AzPolicyDefinition -Name "avd-network-security-group" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-network-security-group.json

$avdnic = New-AzPolicyDefinition -Name "avd-diagnostics-nic" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-nic.json

$avdvm = New-AzPolicyDefinition -Name "avd-virtual-machine" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-virtual-machine.json

$avdvnet = New-AzPolicyDefinition -Name "avd-virtual-network" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-virtual-network.json



# $job = Start-AzPolicyComplianceScan -ResourceGroupName "imageBuilderRG"
# $jobStatus = ""
# $count = 0
# while ($jobStatus -notlike "Completed") { 
#     Write-Host "Waiting for the policy Remediation"
#     $jobStatus = $job.State
#     write-output "starting 60 second sleep"
#     start-sleep -Seconds 60
#     $count += 1
#     if ($count -gt 7) { 
#         Write-Error "seven minutes wait for the policy Remediation ended, canceling script"
#         #Exit
#     }
# }