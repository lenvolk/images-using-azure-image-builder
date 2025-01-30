# Ref https://learn.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks-faq
# https://github.com/johnthebrit/RandomStuff/blob/master/AzureVMs/CheckCache.ps1

[CmdletBinding()]
param([Parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]
      [string]$Location,
      [Parameter(Mandatory=$true)]
      [long]$OSImageSizeInGB
      )
 
Function HasSupportEphemeralOSDisk([object[]] $capability)
{
    return $capability | where { $_.Name -eq "EphemeralOSDiskSupported" -and $_.Value -eq "True"}
}
 
Function Get-MaxTempDiskAndCacheSize([object[]] $capabilities)
{
    $MaxResourceVolumeGB = 0;
    $CachedDiskGB = 0;
 
    foreach($capability in $capabilities)
    {
        if ($capability.Name -eq "MaxResourceVolumeMB")
        { $MaxResourceVolumeGB = [int]($capability.Value / 1024) }
 
        if ($capability.Name -eq "CachedDiskBytes")
        { $CachedDiskGB = [int]($capability.Value / (1024 * 1024 * 1024)) }
    }
 
    return ($MaxResourceVolumeGB, $CachedDiskGB)
}
 
Function Get-EphemeralSupportedVMSku
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [long]$OSImageSizeInGB,
        [Parameter(Mandatory=$true)]
        [string]$Location
    )
 
    $VmSkus = Get-AzComputeResourceSku $Location | Where-Object { $_.ResourceType -eq "virtualMachines" -and (HasSupportEphemeralOSDisk $_.Capabilities) -ne $null }
 
    $Response = @()
    foreach ($sku in $VmSkus)
    {
        ($MaxResourceVolumeGB, $CachedDiskGB) = Get-MaxTempDiskAndCacheSize $sku.Capabilities
 
        $Response += New-Object PSObject -Property @{
            ResourceSKU = $sku.Size
            TempDiskPlacement = @{ $true = "NOT SUPPORTED"; $false = "SUPPORTED"}[$MaxResourceVolumeGB -lt $OSImageSizeInGB]
            CacheDiskPlacement = @{ $true = "NOT SUPPORTED"; $false = "SUPPORTED"}[$CachedDiskGB -lt $OSImageSizeInGB]
        };
    }
 
    return $Response
}
 
Get-EphemeralSupportedVMSku -OSImageSizeInGB $OSImageSizeInGB -Location $Location | Format-Table


#### Creating a VM with an ephemeral OS disk

$refVmRg = 'imageBuilderRG' 
$location = (Get-AzResourceGroup -Name $refVmRg).Location
$vnetName = 'aibVNet' 
$subnetName = 'aibSubnet'
$image = "/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44/resourceGroups/SIGRG/providers/Microsoft.Compute/galleries/LabSIG/images/avd-win11/versions/0.202210.031625"
$VM_User = "aibadmin"
$WinVM_Password = "P@ssw0rdP@ssw0rd"

$VMIP=( az vm create --resource-group $refVmRg --name "pilotVM1" `
                    --admin-username $VM_User --admin-password $WinVM_Password `
                    --image $image --location $location --public-ip-sku Standard `
                    --size 'Standard_D16as_v4' `
                    --ephemeral-os-disk true `
                    --ephemeral-os-disk-placement ResourceDisk `
                    --os-disk-caching ReadOnly `
                    --tags 'Name=PilotImage' `
                    --vnet-name $vnetName `
                    --subnet $subnetName `
                    --nsg '""' `
                    --query publicIpAddress -o tsv)