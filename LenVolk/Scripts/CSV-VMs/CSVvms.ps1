###################################################################################################################################################################################################################################################
# !!! Make sure PS 7 is installed https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3#installing-the-msi-package
###################################################################################################################################################################################################################################################

# Authenticate to Azure and select the subscription
.\Authenticate2Azure.ps1

# Please Provide VMs local admin credentials
Write-Host "Please Provide VMs local admin credentials: " -ForegroundColor Yellow
$LocalAdmin = Get-Credential
If ($null -eq $LocalAdmin) {
    Write-Host "Local Admin credentials are not provided, will be used from CSV file..." -ForegroundColor Yellow 
}

########## To check the VM's SKU by location and AV Zones ####################################################
# Get-AzComputeResourceSku | Where-Object { $_.Locations -contains "USGovVirginia" } | Where-Object { $_.Name -like 'Standard_D*' }
##############################################################################################################

$VMcsv = Import-Csv "C:\Temp\BackUP\Temp\images-using-azure-image-builder\LenVolk\Scripts\CSV-VMs\azurevms.csv"

##############################################################################################################
##############################################################################################################

$VMcsv | ForEach-Object -Parallel {

$location = $_.location
$VMRGname = $_.VMRGname

$ExistingVNET = $_.ExistingVNET
$Existsubnetname = $_.Existsubnetname

$SAname = $_.SAname
$SARGname = $_.SARGname

$vmName = $_.vmName

$PrivateIpAddress = $_.PrivateIpAddress


$AvailabilitySet = $_.AvailabilitySet
$AvailabilitySetRG = $_.AvailabilitySetRG

$OSFamily = $_.OSFamily
$Publisher = ("Microsoft" + (($OSFamily -split " " | select -First 2) -join ""))
$offer = ($OSFamily -split " " | select -First 2) -join ""
$Sku = ($OSFamily -split " " | select -Last 2) -join "-" 

# Size of the VM
$vmSize = $_.vmSize

# Choosing the latest version
$version = $_.version

# Storage type for the OS Disk
$OSstorageType = $_.OSstorageType 
# Storage type for the Data Disk
$DataStorageType1 = $_.DataStorageType1  # Choose between Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_ZRS, and Premium_LRS based on your scenario
$dataDiskSize1 = $_.dataDiskSize1

$DataStorageType2 = $_.DataStorageType2  # Choose between Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_ZRS, and Premium_LRS based on your scenario
$dataDiskSize2 = $_.dataDiskSize2

$DataStorageType3 = $_.DataStorageType3  # Choose between Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_ZRS, and Premium_LRS based on your scenario
$dataDiskSize3 = $_.dataDiskSize3
# Setting up the Local Admin on the VM
$VM_User = $_.VM_User
$WinVM_Password = $_.WinVM_Password
if ($null -eq $VM_User -or $null -eq $WinVM_Password) {
    Write-Host "Local Admin credentials are not provided in the CSV file, will be used from prompt..." -ForegroundColor Yellow
    $cred = $LocalAdmin
}
else {
    Write-host "Local Admin credentials are provided, will be used from CSV file..."
    $VM_User = $LocalAdmin.UserName
    $WinVM_Password = $LocalAdmin.GetNetworkCredential().Password
    $securePassword = ConvertTo-SecureString $WinVM_Password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($VM_User, $securePassword)
}


##############################################################################################################
##############################################################################################################

# Get existing AvailabilitySet

If ($AvailabilitySet -gt 0){
$AVSetID = (Get-AzAvailabilitySet -ResourceGroupName $AvailabilitySetRG -Name $AvailabilitySet).id
$vm = New-AzVMConfig `
    -VMName $vmName `
    -VMSize $vmSize `
    -AvailabilitySetId $AVSetID
# Write-Host "###################################"
# Write-Host "VM's config with AVSet is $($vm.AvailabilitySetReference.Id)"
# Write-Host "###################################"
}
else {
    $vm = New-AzVMConfig `
    -VMName $vmName `
    -VMSize $vmSize
}

# Existing Subnet within the VNET for the this virtual machine
$vnet = Get-AzVirtualNetwork -Name $ExistingVNET 
$subnet = ($vnet.Subnets | Where-Object { $_.Name -eq $Existsubnetname }).id


# Set Bood Diagnostic
$vm = Set-AzVMBootDiagnostic -VM $VM -Enable -ResourceGroupName $SARGname -StorageAccountName $SAname

$vm = Set-AzVMOperatingSystem `
   -VM $vm -Windows `
   -ComputerName $vmName `
   -Credential $cred `
   -ProvisionVMAgent `
   -EnableAutoUpdate  `
   -TimeZone 'Eastern Standard Time'
 

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

# Data Disk
If ($dataDiskSize1 -gt 0){
    $dataDiskName = "$vmName-DataDisk1"
    $dataDiskSize = $dataDiskSize1
    $datadiskConfig = New-AzDiskConfig -SkuName $DataStorageType1 -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize
    $dataDisk01 = New-AzDisk -DiskName $dataDiskName -Disk $datadiskConfig -ResourceGroupName $VMRGname -WarningAction:SilentlyContinue
    $vm = Add-AzVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk01.Id -Lun 0 -DiskSizeInGB $dataDiskSize -Caching ReadWrite
}
if ($dataDiskSize2 -gt 0) {
    $dataDiskName = "$vmName-DataDisk2"
    $dataDiskSize = $dataDiskSize2
    $datadiskConfig = New-AzDiskConfig -SkuName $DataStorageType2 -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize
    $dataDisk02 = New-AzDisk -DiskName $dataDiskName -Disk $datadiskConfig -ResourceGroupName $VMRGname -WarningAction:SilentlyContinue
    $vm = Add-AzVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk02.Id -Lun 1 -DiskSizeInGB $dataDiskSize -Caching ReadWrite  
}
if ($dataDiskSize3 -gt 0) {
    $dataDiskName = "$vmName-DataDisk3"
    $dataDiskSize = $dataDiskSize3
    $datadiskConfig = New-AzDiskConfig -SkuName $DataStorageType3 -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize
    $dataDisk03 = New-AzDisk -DiskName $dataDiskName -Disk $datadiskConfig -ResourceGroupName $VMRGname -WarningAction:SilentlyContinue
    $vm = Add-AzVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk03.Id -Lun 2 -DiskSizeInGB $dataDiskSize -Caching ReadWrite  
}

# Create the VM
$vm = New-AzVM -ResourceGroupName $VMRGname -Location $location -VM $vm -LicenseType "Windows_Server" -WarningAction:SilentlyContinue

}

########################################################
# Wait for VMs to be ready, display status "VM running"
########################################################
foreach ($VM in $VMcsv)
{
$displayStatus = ""
$count = 0
while ($displayStatus -notlike "VM running") { 
    Write-Host "Waiting for the VM display status to change to VM is running"
    $displayStatus = (get-azvm -Name $VM.vmName -ResourceGroupName $VM.VMRGname -Status).Statuses[1].DisplayStatus
    write-output "starting 30 second sleep"
    start-sleep -Seconds 30
    $count += 1
    if ($count -gt 7) { 
        Write-Error "five minute wait for VM to start ended, canceling script"
        Exit
    }
}
Write-Host "###################################"
"Running VM {0}" -f $VM.vmName 
Write-Host "###################################"
}
################################################################################################
# Domain Join (Please provide the "DomainName" parameter if you want to join the VM to Azure AD)
################################################################################################

$ToDomainJoin = Read-Host "`nAdd VMs to the Domain? (Y or N)"
{

    If($ToDomainJoin.ToUpper() -eq 'Y'){




        Write-Host "Running Domain Join script..."

        $VMcsv | ForEach-Object -Parallel {

            If (($_.DomainName -gt 0) -and ($_.DomainName -ne "FALSE")) {
            Invoke-AzVMRunCommand `
                -ResourceGroupName $_.VMRGname `
                -VMName $_.vmName `
                -CommandId 'RunPowerShellScript' `
                -Parameter @{DomainName = $_.DomainName;OUPath = $_.OUPath;user = $_.AdminUser;pass = $_.AdminPass} `
                -ScriptPath '.\AD_Add_PSscript.ps1'
            }

        }
    }
    else {
        Write-Host "Exiting..." -ForegroundColor Yellow
        Write-Host "###################################"
        Write-Host "Domain Join is not selected"
        Write-Host "###################################"
    }
}

######################
# End of Script

# Validate AV Set with VMs
# $VMlist = Get-AzAvailabilitySet -ResourceGroupName 000tst -Name GovAS01
# $i=0
# foreach($vm in $VMlist.VirtualMachinesReferences){
#    "VM{0}: {1}" -f $i,($vm.Id.Split('/'))[-1]
#    $i++
# }