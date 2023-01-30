# $subscription = "c6aa1fdc-66a8-446e-8b37-7794cd545e44"
# Connect-AzAccount -Subscription $subscription
# Set-AzContext -Subscription "AzIntConsumption"
# Disconnect-AzAccount
#
 
# Create Report Array
$report = @()
 
# Record all the subscriptions in a Text file  
$SubscriptionIds = "c6aa1fdc-66a8-446e-8b37-7794cd545e44" #Get-Content -Path "c:\inputs\Subscriptions.txt"
Foreach ($SubscriptionId in $SubscriptionIds) 
{
$reportName = "VM-Details.csv"
 
# Select the subscription  
Select-AzSubscription $subscriptionId
  
# Get all the VMs from the selected subscription
$vms = Get-AzVM
  
# Get all the Public IP Address
$publicIps = Get-AzPublicIpAddress
  
# Get all the Network Interfaces
$nics = Get-AzNetworkInterface | ?{ $_.VirtualMachine -NE $null} 
foreach ($nic in $nics) { 
    # Creating the Report Header we have taken maxium 5 disks but you can extend it based on your need
    $ReportDetails = "" | Select VmName, ResourceGroupName, Region, VmSize, VirtualNetwork, Subnet, PrivateIpAddress, OsType, PublicIPAddress, NicName, ApplicationSecurityGroup, OSDiskName,OSDiskTier, OSDiskCaching, OSDiskSize, DataDiskCount, DataDisk1Name, DataDisk1Tier, DataDisk1Size,DataDisk1Caching, DataDisk2Name,DataDisk2Tier, DataDisk2Size,DataDisk2Caching, DataDisk3Name, DataDisk3Tier, DataDisk3Size,DataDisk3Caching,  DataDisk4Name, DataDisk4Tier, DataDisk4Size,DataDisk4Caching, DataDisk5Name,DataDisk5Tier, DataDisk5Size,DataDisk5Caching
   #Get VM IDs
    $vm = $vms | ? -Property Id -eq $nic.VirtualMachine.id 
    foreach($publicIp in $publicIps) { 
        if($nic.IpConfigurations.id -eq $publicIp.ipconfiguration.Id) {
            $ReportDetails.PublicIPAddress = $publicIp.ipaddress
            } 
        } 
        $ReportDetails.OsType = $vm.StorageProfile.OsDisk.OsType 
        $ReportDetails.VMName = $vm.Name 
        $ReportDetails.ResourceGroupName = $vm.ResourceGroupName 
        $ReportDetails.Region = $vm.Location 
        $ReportDetails.VmSize = $vm.HardwareProfile.VmSize
        $ReportDetails.VirtualNetwork = $nic.IpConfigurations.subnet.Id.Split("/")[-3] 
        $ReportDetails.Subnet = $nic.IpConfigurations.subnet.Id.Split("/")[-1] 
        $ReportDetails.PrivateIpAddress = $nic.IpConfigurations.PrivateIpAddress 
        $ReportDetails.NicName = $nic.Name 
        $ReportDetails.ApplicationSecurityGroup = $nic.IpConfigurations.ApplicationSecurityGroups.Id 
        $ReportDetails.OSDiskName = $vm.StorageProfile.OsDisk.Name 
        $ReportDetails.OSDiskSize = $vm.StorageProfile.OsDisk.DiskSizeGB
        $ReportDetails.OSDiskCaching = $vm.StorageProfile.OsDisk.Caching
        $ReportDetails.DataDiskCount = $vm.StorageProfile.DataDisks.count
        $ReportDetails.OSDiskTier = ((Get-AzDisk -ResourceGroupName $vm.ResourceGroupName  -DiskName $vm.OsDisk.Name).Tier | Out-String).Trim()
 
        if ($vm.StorageProfile.DataDisks.count -gt 0)
        {
         $disks= $vm.StorageProfile.DataDisks
     foreach($disk in $disks)
        {
        If ($disk.Lun -eq 0)
        {
       $ReportDetails.DataDisk1Name = $vm.StorageProfile.DataDisks[$disk.Lun].Name 
       $ReportDetails.DataDisk1Size =  $vm.StorageProfile.DataDisks[$disk.Lun].DiskSizeGB 
       $ReportDetails.DataDisk1Caching =  $vm.StorageProfile.DataDisks[$disk.Lun].Caching 
       $ReportDetails.DataDisk1Tier = ((Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $vm.StorageProfile.DataDisks[$disk.Lun].Name).Tier | Out-String).Trim()
        }
        elseif($disk.Lun -eq 1)
        {
        $ReportDetails.DataDisk2Name = $vm.StorageProfile.DataDisks[$disk.Lun].Name 
        $ReportDetails.DataDisk2Size =  $vm.StorageProfile.DataDisks[$disk.Lun].DiskSizeGB 
        $ReportDetails.DataDisk2Caching =  $vm.StorageProfile.DataDisks[$disk.Lun].Caching 
        $ReportDetails.DataDisk2Tier = ((Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $vm.StorageProfile.DataDisks[$disk.Lun].Name).Tier | Out-String).Trim()
        }
        elseif($disk.Lun -eq 2)
        {
        $ReportDetails.DataDisk3Name = $vm.StorageProfile.DataDisks[$disk.Lun].Name 
        $ReportDetails.DataDisk3Size =  $vm.StorageProfile.DataDisks[$disk.Lun].DiskSizeGB 
        $ReportDetails.DataDisk3Caching =  $vm.StorageProfile.DataDisks[$disk.Lun].Caching 
        $ReportDetails.DataDisk3Tier = ((Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $vm.StorageProfile.DataDisks[$disk.Lun].Name).Tier | Out-String).Trim()
        }
        elseif($disk.Lun -eq 3)
        {
        $ReportDetails.DataDisk4Name = $vm.StorageProfile.DataDisks[$disk.Lun].Name 
        $ReportDetails.DataDisk4Size =  $vm.StorageProfile.DataDisks[$disk.Lun].DiskSizeGB 
        $ReportDetails.DataDisk4Caching =$vm.StorageProfile.DataDisks[$disk.Lun].Caching 
        $ReportDetails.DataDisk4Tier = ((Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $vm.StorageProfile.DataDisks[$disk.Lun].Name).Tier | Out-String).Trim()
        }
        elseif($disk.Lun -eq 4)
        {
        $ReportDetails.DataDisk5Name = $vm.StorageProfile.DataDisks[$disk.Lun].Name 
        $ReportDetails.DataDisk5Size =  $vm.StorageProfile.DataDisks[$disk.Lun].DiskSizeGB 
        $ReportDetails.DataDisk5Caching =  $vm.StorageProfile.DataDisks[$disk.Lun].Caching 
        $ReportDetails.DataDisk5Tier = ((Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $vm.StorageProfile.DataDisks[$disk.Lun].Name).Tier | Out-String).Trim()
        }
       }
        }
        $report+=$ReportDetails 
    } 
} #end of subscription for each loop 
      
$report | ft -AutoSize VmName, ResourceGroupName, Region, VmSize, VirtualNetwork, Subnet, PrivateIpAddress, OsType, PublicIPAddress, NicName, ApplicationSecurityGroup, OSDiskName, OSDiskTier, OSDiskCaching, OSDiskSize, DataDiskCount, DataDisk1Name, DataDisk1Tier, DataDisk1Size,DataDisk1Caching, DataDisk2Name,DataDisk2Tier, DataDisk2Size,DataDisk2Caching, DataDisk3Name, DataDisk3Tier, DataDisk3Size,DataDisk3Caching,  DataDisk4Name, DataDisk4Tier, DataDisk4Size,DataDisk4Caching, DataDisk5Name,DataDisk5Tier, DataDisk5Size,DataDisk5Caching
 
#Change the path based on your convenience
$report | Export-CSV  "c:\temp\$reportName"
