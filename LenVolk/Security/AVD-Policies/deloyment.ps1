

$avdappgrp = New-AzPolicyDefinition -ManagementGroupName "volk-SandBox" -Name "policy-deploy-diagnostics-avd-application-group" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-application-group.json

$avdappgrp = New-AzPolicyDefinition -ManagementGroupName "volk-SandBox" -Name "diagnostic settings for File Services" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-azure-files.json
$job = Start-AzPolicyComplianceScan -ResourceGroupName "imageBuilderRG"
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