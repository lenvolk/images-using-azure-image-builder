

$avdappgrp = New-AzPolicyDefinition -ManagementGroupName "volk-SandBox" -Name "policy-deploy-diagnostics-avd-application-group" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-application-group.json

$avdappgrp = New-AzPolicyDefinition -ManagementGroupName "volk-SandBox" -Name "diagnostic settings for File Services" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-azure-files.json
