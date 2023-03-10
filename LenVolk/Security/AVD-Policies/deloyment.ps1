

$definition = New-AzPolicyDefinition -ManagementGroupName "volk-SandBox" -Name "policy-deploy-diagnostics-avd-application-group" -Policy ..\AVD-Policies\monitoring\policy-definitions\policy-definition-es-deploy-diagnostics-avd-application-group.json
