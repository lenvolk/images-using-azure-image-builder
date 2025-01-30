# Connect to portal
# PS 
# MAC
# $subscription = "DemoSub"
# Connect-AzAccount -Environment AzureCloud -Subscription $subscription 
# Set-AzContext -Subscription $subscription
# Disconnect-AzAccount
# MAG
# $subscription = "AzGovInt"
# Connect-AzAccount -Environment AzureUSGovernment -Subscription $subscription 
# Set-AzContext -Subscription $subscription



$location = "usdodeast"
$VMRGname = "000tst"

$ExistingVNET = "MainVNET"
$Existsubnetname = "srv_subnet"

$SAname = "azuredevguestdiag"
$SARGname = "LAWs"

$vmName = "01vm"

$PrivateIpAddress = "10.10.10.20"


$AvailabilitySet = "GovAS01"
$AvailabilitySetRG = "000tst"

$OSFamily = "Windows Server 2019 Datacenter"
$Publisher = ("Microsoft" + (($OSFamily -split " " | select -First 2) -join ""))
$offer = ($OSFamily -split " " | select -First 2) -join ""
$Sku = ($OSFamily -split " " | select -Last 2) -join "-" 

# Size of the VM
$vmSize = "Standard_B2s"

# Choosing the latest version
$version = "latest"

# Storage type for the OS Disk
$OSstorageType = 'StandardSSD_LRS' 
# Storage type for the Data Disk
$DataStorageType1 = 'Standard_LRS'  # Choose between Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_ZRS, and Premium_LRS based on your scenario
$dataDiskSize1 = 10

$DataStorageType2 = 'StandardSSD_LRS'  # Choose between Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_ZRS, and Premium_LRS based on your scenario
$dataDiskSize2 = 0

$DataStorageType3 = 'StandardSSD_LRS'  # Choose between Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_ZRS, and Premium_LRS based on your scenario
$dataDiskSize3 = 0
# Setting up the Local Admin on the VM
$VM_User = "vmadmin"
$WinVM_Password = "P@ssw0rdP@ssw0rd"
$securePassword = ConvertTo-SecureString $WinVM_Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($VM_User, $securePassword)

##############################################################################################################
##############################################################################################################

# Get existing AvailabilitySet
$AVSetID = (Get-AzAvailabilitySet -ResourceGroupName $AvailabilitySetRG -Name $AvailabilitySet).id
"AvailabilitySetID is {0}" -f $AVSetID

# Existing Subnet within the VNET for the this virtual machine
$vnet = Get-AzVirtualNetwork -Name $ExistingVNET 
$subnet = ($vnet.Subnets | Where-Object { $_.Name -eq $Existsubnetname }).id

# Creation of the new virtual machine with delete option for Disk/NIC together
$vm = New-AzVMConfig `
    -VMName $vmName `
    -VMSize $vmSize `
    -AvailabilitySetId $AVSetID

Write-Host "###################################"
Write-Host "VM's config with AVSet is $($vm.AvailabilitySetReference.Id)"
Write-Host "###################################"

# Set Bood Diagnostic
$vm = Set-AzVMBootDiagnostic -VM $VM -Enable -ResourceGroupName $SARGname -StorageAccountName $SAname

$vm = Set-AzVMOperatingSystem `
   -VM $vm -Windows `
   -ComputerName $vmName `
   -Credential $cred `
   -ProvisionVMAgent `
   -EnableAutoUpdate  `
   -TimeZone 'Eastern Standard Time'
 
Write-Host "###################################"
Write-Host "VM's config with TimeZone - AVSet is $($vm.AvailabilitySetReference.Id)"
Write-Host "###################################"

# Create New network interface for the virtual machine
$NIC = New-AzNetworkInterface -Name "$vmName-nic1" -ResourceGroupName $VMRGname -Location $location -SubnetID $subnet -PrivateIpAddress $PrivateIpAddress -Force
$vm = Add-AzVMNetworkInterface -VM $vm `
    -Id $NIC.Id `
    -DeleteOption "Delete"

$vm = Set-AzVMSourceImage -VM $vm `
   -PublisherName $publisher `
   -Offer $offer `
   -Skus $sku `
   -Version $version 

# OS Disk
$vm = Set-AzVMOSDisk -VM $vm `
   -StorageAccountType $OSstorageType `
   -CreateOption "FromImage" `
   -DeleteOption "Delete"

Write-Host "###################################"
Write-Host "VM's config with OS Disk - AVSet is $($vm.AvailabilitySetReference.Id)"
Write-Host "###################################"

# Data Disk
If ($dataDiskSize1 -gt 0){
    $dataDiskName = "$vmName-DataDisk1"
    $dataDiskSize = $dataDiskSize1
    $datadiskConfig = New-AzDiskConfig -SkuName $DataStorageType1 -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize
    $dataDisk01 = New-AzDisk -DiskName $dataDiskName -Disk $datadiskConfig -ResourceGroupName $VMRGname
    $vm = Add-AzVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk01.Id -Lun 0 -DiskSizeInGB $dataDiskSize -Caching ReadWrite
}
if ($dataDiskSize2 -gt 0) {
    $dataDiskName = "$vmName-DataDisk2"
    $dataDiskSize = $dataDiskSize2
    $datadiskConfig = New-AzDiskConfig -SkuName $DataStorageType2 -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize
    $dataDisk02 = New-AzDisk -DiskName $dataDiskName -Disk $datadiskConfig -ResourceGroupName $VMRGname
    $vm = Add-AzVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk02.Id -Lun 1 -DiskSizeInGB $dataDiskSize -Caching ReadWrite  
}
if ($dataDiskSize3 -gt 0) {
    $dataDiskName = "$vmName-DataDisk3"
    $dataDiskSize = $dataDiskSize3
    $datadiskConfig = New-AzDiskConfig -SkuName $DataStorageType3 -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize
    $dataDisk03 = New-AzDisk -DiskName $dataDiskName -Disk $datadiskConfig -ResourceGroupName $VMRGname
    $vm = Add-AzVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk03.Id -Lun 2 -DiskSizeInGB $dataDiskSize -Caching ReadWrite  
}

# Create the VM
$vm = New-AzVM -ResourceGroupName $VMRGname -Location $location -VM $vm -LicenseType "Windows_Server"

Write-Host "###################################"
Write-Host "VM has been provisioned - AVSet is $($vm.AvailabilitySetReference.Id)"
Write-Host "###################################"

# Validate AV Set with VMs
$VMlist = Get-AzAvailabilitySet -ResourceGroupName $AvailabilitySetRG -Name $AvailabilitySet
$i=0
foreach($vm in $VMlist.VirtualMachinesReferences){
   "VM{0}: {1}" -f $i,($vm.Id.Split('/'))[-1]
   $i++
}