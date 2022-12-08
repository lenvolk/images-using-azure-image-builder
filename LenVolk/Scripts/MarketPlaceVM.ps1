
##########################################################################
# Get-AzVMImageSku -Location eastus2 -PublisherName MicrosoftWindowsDesktop -Offer office-365 | select Skus | Where-Object { $_.Skus -like 'win11*'}
# Get-AzVmImageSku -Location eastus2 -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-10'| Select Skus | Where-Object { $_.Skus -like '*avd*'}  #!!! Only the -avd are multi-session
# az vm image list --publisher MicrosoftWindowsDesktop --sku g2 --output table --all
##########################################################################

$VMLocalAdminUser = "aibadmin"
$VMLocalPassword = "P@ssw0rdP@ssw0rd"
$VMLocalAdminSecurePassword = ConvertTo-SecureString $VMLocalPassword -AsPlainText -Force

$rgName = "imageBuilderRG"
$location = (Get-AzResourceGroup -Name $refVmRg).Location
$VMName = "avd-win11-0"
$VMSize = "Standard_B2ms"
$ImageSku = "win11-22h2-avd"
$ImageOffer = "Windows-11"
$ImagePublisher = "MicrosoftWindowsDesktop"
$DiskSizeGB = 128
$nicName = "nic1-$vmName"

$vnetResourceGroup = 'imageBuilderRG'
$vnetName = "aibVNet"
$subnet = "aibSubnet"

$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetResourceGroup
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnet -VirtualNetwork $vnet
$NIC = New-AzNetworkInterface -Name $nicName -ResourceGroupName $vnetResourceGroup -Location $location -Subnet $subnet
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMOSDisk -Windows -VM $VirtualMachine -CreateOption FromImage -DiskSizeInGB $DiskSizeGB
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $ImagePublisher -Offer $ImageOffer -Skus $ImageSku -Version latest

$job = $newVm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $VirtualMachine -LicenseType "Windows_Client" -AsJob
# View the status of the job
# $job.State
