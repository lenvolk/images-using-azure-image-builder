
##########################################################################
# Get-AzVMImageSku -Location eastus2 -PublisherName MicrosoftWindowsDesktop -Offer office-365 | select Skus | Where-Object { $_.Skus -like 'win11*'}
# Get-AzVmImageSku -Location eastus2 -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-11'| Select Skus | Where-Object { $_.Skus -like '*avd*'}  #!!! Only the -avd are multi-session
# az vm image list --publisher MicrosoftWindowsDesktop --sku g2 --output table --all
##########################################################################

$TotalVMs = 3

$VMLocalAdminUser = "aibadmin"
$VMLocalPassword = "P@ssw0rdP@ssw0rd"
$VMLocalAdminSecurePassword = ConvertTo-SecureString $VMLocalPassword -AsPlainText -Force

$rgName = "imageBuilderRG"
$location = (Get-AzResourceGroup -Name $rgName).Location
$VMSize = "Standard_B2ms"
$ImageSku = "win11-22h2-avd"
$ImageOffer = "Windows-11"
$ImagePublisher = "MicrosoftWindowsDesktop"
$DiskSizeGB = 128

$vnetResourceGroup = 'imageBuilderRG'
$vnetName = "aibVNet"
$subnet = "aibSubnet"

$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetResourceGroup
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnet -VirtualNetwork $vnet

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

for ($i = 1; $i -le $TotalVMs; $i++) {
    $vmName = "avd-win11-$i"
    $nicName = "nic1-$vmName"
    $NIC = New-AzNetworkInterface -Name $nicName -ResourceGroupName $vnetResourceGroup -Location $location -Subnet $subnet

    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMOSDisk -Windows -VM $VirtualMachine -CreateOption FromImage -DiskSizeInGB $DiskSizeGB
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $ImagePublisher -Offer $ImageOffer -Skus $ImageSku -Version latest

    $job = $newVm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $VirtualMachine -LicenseType "Windows_Client" -AsJob

}

### Wait for VM to be ready, display job status "Completed"
# $jobStatus = ""
# $count = 0
# while ($jobStatus -notlike "Completed") { 
#     Write-Host "Waiting for the VM to be provisioned"
#     $jobStatus = $job.State
#     write-output "starting 30 second sleep"
#     start-sleep -Seconds 30
#     $count += 1
#     if ($count -gt 7) { 
#         Write-Error "five minute wait for VM to start ended, canceling script"
#         #Exit
#     }
# }