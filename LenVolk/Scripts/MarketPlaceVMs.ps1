
##########################################################################
# Get-AzVMImageSku -Location eastus2 -PublisherName MicrosoftWindowsDesktop -Offer office-365 | select Skus | Where-Object { $_.Skus -like 'win11*'}
# Get-AzVmImageSku -Location eastus2 -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-11'| Select Skus | Where-Object { $_.Skus -like '*avd*'}  #!!! Only the -avd are multi-session
# az vm image list --publisher MicrosoftWindowsDesktop --sku g2 --output table --all
# https://bradleyschacht.com/create-new-azure-vm-with-powershell/
##########################################################################

$TotalVMs = 3

$VMLocalAdminUser = "aibadmin"
$VMLocalPassword = "P@ssw0rdP@ssw0rd"
$VMLocalAdminSecurePassword = ConvertTo-SecureString $VMLocalPassword -AsPlainText -Force

$rgName = "imageBuilderRG"
$location = (Get-AzResourceGroup -Name $rgName).Location
$VMSize = "Standard_B2ms"
# $ImageSku = "win11-22h2-avd"
$ImageSku = "win11-22h2-avd-m365"
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
    $job = New-AzVM -ResourceGroupName $rgName -Location $location -VM $VirtualMachine -LicenseType "Windows_Client" -AsJob

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


#############################################
# Provisioin VM via automation account      #
#############################################

# #Set the variables for the VM
# $vmName = "automatedVM"
# $vmSize = "Standard_B4ms"
# $vmImage = "Win2019Datacenter"
# $vmLocation = "eastus2"
# $vmResourceGroup = "automatedVMRG"
# $vmAdminUsername = "adminuser"
# $vmPassword = "P@ssw0rd1234"
# $VMResourceID = ""
# ##$vmPublicIPName = "automatedVMIP"
# ##$vmNsgName = "automatedVMNSG"

# #Connect to Azure with system-assigned managed identity
# # Ensures you do not inherit an AzContext in your runbook
# Disable-AzContextAutosave -Scope Process

# # Connect to Azure with system-assigned managed identity
# $AzureContext = (Connect-AzAccount -Identity).context

# # Set and store context
# $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext


# ##Create new AZ VM that will delete itself after 24 hours or when the VM is stopped
# ##This script will create a new VM in the existing resource group that is specified in the script


# #Create Credentials
# $vmCredential = New-Object System.Management.Automation.PSCredential ($vmAdminUsername, (ConvertTo-SecureString -String $vmPassword -AsPlainText -Force))

# #Create the VM
# New-AzVM -ResourceGroupName $vmResourceGroup -Name $vmName -Location $vmLocation -Size $vmSize -Image $VMResourceID -Credential $vmCredential -NetworkInterfaceDeleteOption Delete -OSDiskDeleteOption Delete

# ##Create loop that checks VM status every 5 minutes
# ##If the VM is stopped, delete the VM 
# ##If the VM is running, wait 5 minutes and check again
# ##If the VM has been running for 24 hours, delete the VM

# ##wait 5 minutes before starting the loop to check the status of the VM
# Start-Sleep -Seconds 300

# #Set the variables for the loop including validation that the server has been provisioned and the time the VM will be deleted  hours after creation
# $VMObject = Get-AzVM -ResourceGroupName $vmResourceGroup -Name $vmName -Status
# $vmStatus = $VMObject.Statuses[0].DisplayStatus
# $vmStartTime = Get-Date
# $vmStopTime = $vmStartTime.AddMinutes(170)
# $osdisks = $VMObject.disks[0].name
# ##Create the loop that checks the status of the VM if the VM is running it will wait 5 minutes and check again 
# ##If the VM is stopped, delete the VM
# while ($vmStatus -eq "Provisioning succeeded")
# {
#     Start-Sleep -Seconds 60
#     Get-AzVM -ResourceGroupName $vmResourceGroup -Name $vmName -ErrorVariable VMnotPresent -ErrorAction SilentlyContinue 
#     if ($VMnotPresent)
#         {
#         $vmStatus = "VM deleted"
#         }
#     else
#         {
#         $vmState = (Get-AzVM -ResourceGroupName $vmResourceGroup -Name $vmName -Status ).Statuses[1].DisplayStatus
#         if ($vmState -eq "VM deallocated")
#         {
#             Remove-AzVM -ResourceGroupName $vmResourceGroup -Name $vmName -Force -ForceDeletion $true
#             Start-Sleep -Seconds 60
#             Remove-AZDisk -ResourceGroupName $vmResourceGroup -DiskName $osdisks -Force            
#         }
#         elseif ((Get-Date) -gt $vmStopTime)
#         {
#         Remove-AzVM -ResourceGroupName $vmResourceGroup -Name $vmName -ForceDeletion $true -Force
#         Start-Sleep -Seconds 60
#         Remove-AZDisk -ResourceGroupName $vmResourceGroup -DiskName $osdisks -Force         
#         }
#         }
# }



