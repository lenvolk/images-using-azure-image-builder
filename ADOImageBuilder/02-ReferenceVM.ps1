$vmName = "ReferenceVM"
$rgName = "ImageRefRG"

$VMSize = "Standard_D16as_v5"
$ImageSku = "win11-24h2-avd"
$ImageOffer = "Windows-11"
$ImagePublisher = "MicrosoftWindowsDesktop"
$DiskSizeGB = 128
$VMLocalAdminUser = "aibadmin"
$VMLocalPassword = "P@ssw0rdP@ssw0rd"
$VMLocalAdminSecurePassword = ConvertTo-SecureString $VMLocalPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
$vnetResourceGroup = "AVDNetWork"
$vnetName = "AVDVNet"
$subnet = "PooledHP"
$nicName = "$vmName-nic1"

if (-not (Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $rgName -Location "EastUS2"
} else {
    Write-Host "Resource group already exists"
}

$location = (Get-AzResourceGroup -Name $rgName).Location
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetResourceGroup
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnet -VirtualNetwork $vnet

if (-not (Get-AzVm -ResourceGroupName $rgName -Name $vmName -ErrorAction SilentlyContinue))
{
    $NIC = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -Subnet $subnet

    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize -SecurityType "Standard"
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate -TimeZone 'Eastern Standard Time'
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMOSDisk -Windows -VM $VirtualMachine -CreateOption FromImage -DiskSizeInGB $DiskSizeGB
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $ImagePublisher -Offer $ImageOffer -Skus $ImageSku -Version latest 
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
    $job = New-AzVM -ResourceGroupName $rgName -Location $location -VM $VirtualMachine -LicenseType "Windows_Client" -AsJob

    ### Wait for VM to be ready, display job status "Completed"
    $jobStatus = ""
    $count = 0
    while ($jobStatus -notlike "Completed") { 
        Write-Host "Waiting for the VM to be provisioned"
        $jobStatus = $job.State
        write-output "starting 60 second sleep"
        start-sleep -Seconds 60
        $count += 1
        if ($count -gt 10) { 
            Write-Error "ten minutes wait for VM to start ended, canceling script"
        }
    }
} else {
    Start-AzVm -ResourceGroupName $rgName -Name $vmName
}