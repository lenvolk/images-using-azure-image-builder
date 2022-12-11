#Ref: https://github.com/tsrob50/AzureAutomation/blob/main/HybridWorkerRemoting.ps1
#     https://4sysops.com/archives/running-powershell-scripts-remotely-on-azure-virtual-machines/

#Get service principal details from shared resources
$tenantId = Get-AutomationVariable -Name 'TenantId'
$SPCreds = Get-AutomationPSCredential -Name 'SPCreds'
#Get Domain Join Cred
$djoincred = Get-AutomationPSCredential -Name 'djoincred'
#Get Local Admin Cred
$LocalAdmin = Get-AutomationPSCredential -Name 'LocalAdmin'

$VMRG = "imageBuilderRG"
$DomainName = "lvolk.com"
$OUPath = "OU=PoolHostPool,OU=AVD,DC=lvolk,DC=com"

#Auth with service principal
Connect-AzAccount -ServicePrincipal -Credential $SPCreds -Tenant $tenantId

Set-AzContext -SubscriptionId "c6aa1fdc-66a8-446e-8b37-7794cd545e44"
# write-output "Hello from SPN $SPCreds"

# Get Running windows VMs
$RunningVMs = (get-azvm -ResourceGroupName $VMRG -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows"} 

$RunningVMs | ForEach-Object {
Invoke-AzVMRunCommand `
    -ResourceGroupName $_.ResourceGroupName `
    -VMName $_.Name `
    -CommandId 'RunPowerShellScript' `
    -ScriptString { Add-Computer -DomainName $DomainName -OUPath $OUPath -Credential $credential -Force }
}