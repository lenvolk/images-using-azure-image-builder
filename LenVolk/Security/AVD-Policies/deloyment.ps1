

# $avdappgrp = New-AzPolicyDefinition -ManagementGroupName "volk-SandBox" -Name "policy-deploy-diagnostics-avd-application-group" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-application-group.json
# to the current subscription
$avdappgrp = New-AzPolicyDefinition -Name "policy-deploy-diagnostics-avd-application-group" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-application-group.json

# $avdappgrp = New-AzPolicyDefinition -ManagementGroupName "volk-SandBox" -Name "diagnostic settings for File Services" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-azure-files.json
$avdappgrp = New-AzPolicyDefinition -Name "diagnostic settings for File Services" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-azure-files.json

$avdappgrp = New-AzPolicyDefinition -Name "AVD Scaling Plans to Log Analytics workspace" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-scaling-plan.json






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