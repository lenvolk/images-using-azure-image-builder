#######################################
#         Test VMs creation           #
#######################################
$refVmRg = 'ImageRefRG' 
$location = (Get-AzResourceGroup -Name $refVmRg).Location
$vnetRg = 'AVDNetWork'
$vnetName = 'AVDVNet' 
$subnetName = 'PooledHP'
$CompGalRg = "CompGalRG"
$galleryName = "CompGal"
$imageDefinitionName = "ImDefWin11"
# Get the virtual network
$virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName $vnetRg -Name $vnetName
# Get the subnet configuration
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $virtualNetwork

$vmName = "PilotVM01"
$nicName = "$vmName-nic"
$vmSize = "Standard_D2as_v4"
# Setting up the Local Admin on the VM
$VM_User = "aibadmin"
$WinVM_Password = "P@ssw0rdP@ssw0rd"
$securePassword = ConvertTo-SecureString $WinVM_Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($VM_User, $securePassword)


# Create New network interface for the virtual machine
$NIC = New-AzNetworkInterface -Name "$vmName-nic1" -ResourceGroupName $refVmRg -Location $location -Subnet $subnet

# Creation of the new virtual machine with delete option for Disk/NIC together
$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize 

$vm = Set-AzVMOperatingSystem `
   -VM $vm -Windows `
   -ComputerName $vmName `
   -Credential $cred `
   -ProvisionVMAgent `
   -EnableAutoUpdate  `
   -TimeZone 'Eastern Standard Time' 

# Delete option for NIC
$vm = Add-AzVMNetworkInterface -VM $vm `
   -Id $NIC.Id `
   -DeleteOption "Delete"

$imageVersion = Get-AzGalleryImageVersion -ResourceGroupName $CompGalRg -GalleryName $galleryName -GalleryImageDefinitionName $imageDefinitionName | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1
$vm = Set-AzVMSourceImage -VM $vm -Id $imageVersion.Id

# Delete option for Disk
$vm = Set-AzVMOSDisk -VM $vm `
   -StorageAccountType "StandardSSD_LRS" `
   -CreateOption "FromImage" `
   -DeleteOption "Delete"

# The sauce around enabling the Trusted Platform
$vm = Set-AzVmSecurityProfile -VM $vm `
   -SecurityType "TrustedLaunch" 

# The sauce around enabling TPM and Secure Boot
$vm = Set-AzVmUefi -VM $vm `
   -EnableVtpm $true `
   -EnableSecureBoot $true 
$vm = Set-AzVMBootDiagnostic -VM $vm -Disable
New-AzVM -ResourceGroupName $refVmRg -Location $location -VM $vm -LicenseType "Windows_Client"
