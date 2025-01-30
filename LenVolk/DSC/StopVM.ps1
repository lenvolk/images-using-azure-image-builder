param
(
    [Parameter (Mandatory = $false)]
    [object] $WebhookData
)

#Get service principal details from shared resources
$cred = Get-AutomationPSCredential -Name 'SPCreds'
$tenantId = Get-AutomationVariable -Name 'TenantId'

#Auth with service principal
Connect-AzAccount -ServicePrincipal -Credential $cred -Tenant $tenantId

#Convert request body to PS object
$vms = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)

Import-Module Az.Compute

#Loop over each item and stop the VM
foreach($vm in $vms) {
    Stop-AzVM -Name $vm.Name -ResourceGroup $vm.ResourceGroup -Force
}