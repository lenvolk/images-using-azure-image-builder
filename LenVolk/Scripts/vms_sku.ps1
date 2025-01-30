param (
    [string]$ResourceGroup,
    [string]$vms_sku 
)

###################################
# $subscription = "ACC-NPRD-00000-PCEntArch_02"
# $resourcegroup = "wvd-maintenance-hp-rg"
# $vms_sku = "Standard_d4s_v3"
# Set-AzContext -SubscriptionName $subscription
###################################
Write-Host `
    -ForegroundColor Cyan `
    -BackgroundColor Black `
    "Changing SKU to $vms_sku in the $ResourceGroup"


$vms = (Get-AzVM -ResourceGroupName $ResourceGroup)
$vms | ForEach-Object -Parallel {
    try {
        $current_vm = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name
        if ($current_vm.HardwareProfile.VmSize -ne $vms_sku) {
            $current_vm.HardwareProfile.VmSize = $vms_sku
            Update-AzVm -ResourceGroupName $_.ResourceGroupName -VM $current_vm
        }
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ("Error resizing the VM: " + $ErrorMessage)
        Break
    }       
}   
