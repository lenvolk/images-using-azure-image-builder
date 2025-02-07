$refVmName = 'ReferenceVM' 
$refVmRg = 'ImageRefRG' 
$CompGalNameRG = 'CompGalRG' 
$CompGalName ='CompGal'
$ImageDefName = 'ImDefWin11'
$vnetRG = 'AVDNetWork'
$vnetName = 'AVDVNet' 
$subnetName = 'PooledHP'
$cseURI = 'https://raw.githubusercontent.com/lenvolk/images-using-azure-image-builder/main/LenVolk/Scripts/Sysprep.ps1'
$galDeploy = $true
$delSnap = $true
$deltempvm  = $true
$DiskSizeInGB = '130'


#Validate the Azure Compute Gallery settings were added correctly if used

Try {
    if ($galDeploy -eq $true) {
        $gallery = Get-AzGallery -ErrorAction Stop -Name $CompGalName -ResourceGroupName $CompGalNameRG
        $galleryDef = Get-AzGalleryImageDefinition -ErrorAction Stop -ResourceGroupName $gallery.ResourceGroupName -GalleryName $CompGalName -GalleryImageDefinitionName $ImageDefName
    }
}
Catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ('Error with Azure Compute Gallery Settings ' + $ErrorMessage)
    Break
}

#Set the date, used as unique ID for artifacts and image version  yyyyMMddHHmm

$date = (get-date -Format yyyyMMddHHmm)

#Set the image name, modify as needed
#Default based off ReferenceVM computer name and date
$imageName = ($refVmName + 'Image' + $date)

#Set the image version (Name)
#Used if adding the image to an Azure Compute Gallery
#Format is 0.yyyyMM.ddHHmm date format for the version to keep unique and increment each new image version
#$imageVersion = "2.0.0"
$imageVersion = '1.' + $date.Substring(0, 6) + '.' + $date.Substring(6, 6)

#Disable breaking change warning message
Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value $true

#Set the location, based on the reference computer resource group location
$location = (Get-AzResourceGroup -Name $refVmRg).Location


##### Start Script #####

#To avoid any confusions (since refVM is in the same RG as tempVM) let's shutdown reference VM - don't really have to do it
Stop-AzVM -ErrorAction Stop -ResourceGroupName $refVmRg -Name $refVmName  -Force | Out-Null

#Create a Snapshot of reference VM OS disk
try {
    Write-Host "Creating a snapshot of $refVmName"
    $vm = Get-AzVM -ErrorAction Stop -ResourceGroupName $refVmRg -Name $refVmName
    $snapshotConfig = New-AzSnapshotConfig -ErrorAction Stop -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $vm.Location -CreateOption copy -SkuName Standard_LRS -Tag @{Name="PilotImage";Image="Pilot"}
    #$snapshot = Update-AzSnapshot -ErrorAction Stop -Snapshot $snapshotConfig -SnapshotName "$refVmName$date" -ResourceGroupName $refVmRg
    $snapshot = New-AzSnapshot -ErrorAction Stop -Snapshot $snapshotConfig -SnapshotName "$refVmName$date" -ResourceGroupName $refVmRg
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ('Error creating snapshot from reference computer ' + $ErrorMessage)
    Break
}

#Create TempOSDisk from the Snapshot
Try {
    $osDiskConfig = @{
        ErrorAction      = 'Stop'
        Location         = $location
        CreateOption     = 'copy'
        SourceResourceID = $snapshot.Id
        Tag              = @{Name="PilotImage";Image="Pilot"}
    }
    write-host "creating the OS disk form the snapshot"
    $osDisk = New-AzDisk -ErrorAction Stop -DiskName 'TempOSDisk' -ResourceGroupName $refVmRg -disk (New-AzDiskConfig @osDiskConfig)
}
Catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ('Error creating the managed disk ' + $ErrorMessage)
    Break
}

$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRG
$SubnetId = (Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet).id

#Create tempNIC for tempVM
Try {
    $nicConfig = @{
        ErrorAction            = 'Stop'
        Name                   = 'tempNic'
        ResourceGroupName      = $refVmRg
        Location               = $location
        SubnetId               = $SubnetId
        Tag                    = @{Name="PilotImage";Image="Pilot"}
    }
    Write-Host "Creating the NIC"
    $nic = New-AzNetworkInterface @nicConfig
}
Catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ('Error creating the NIC ' + $ErrorMessage)
    Break
}

#Create and start the tempVM
Try {
    Write-Host "Creating the temporary capture VM, this will take a couple minutes"
    $capVmName = ('tempVM' + $date) 
    $CapVmConfig = New-AzVMConfig -ErrorAction Stop -VMName $CapVmName -VMSize $vm.HardwareProfile.VmSize
    $capVm = Add-AzVMNetworkInterface -ErrorAction Stop -vm $CapVmConfig -id $nic.Id -DeleteOption "Delete"
    $capVm = Set-AzVMOSDisk -vm $CapVm -ManagedDiskId $osDisk.id -StorageAccountType Standard_LRS -DiskSizeInGB $DiskSizeInGB -CreateOption Attach -Windows -DeleteOption "Delete"
    $capVM = Set-AzVMBootDiagnostic -vm $CapVm -disable
    $capVM = Set-AzVmSecurityProfile -VM $capVM -SecurityType "standard" 
    $capVm = new-azVM -ResourceGroupName $refVmRg -Location $location -vm $capVm -DisableBginfoExtension -Tag @{Name="PilotImage";Image="Pilot"}
}
Catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ('Error creating the VM ' + $ErrorMessage)
    Break
}

#Wait for tempVM to be ready, display status "VM running"
$displayStatus = ""
$count = 0
while ($displayStatus -notlike "VM running") { 
    Write-Host "Waiting for the VM display status to change to VM running"
    $displayStatus = (get-azvm -Name $capVmName -ResourceGroupName $refVmRg -Status).Statuses[1].DisplayStatus
    write-output "starting 30 second sleep"
    start-sleep -Seconds 30
    $count += 1
    if ($count -gt 7) { 
        Write-Error "five minute wait for VM to start ended, canceling script"
        Exit
    }
}

#Run Sysprep from a Custom Script Extension 
try {
    $cseSettings = @{
        ErrorAction       = 'Stop'
        FileUri           = $cseURI 
        ResourceGroupName = $refVmRg
        VMName            = $CapVmName 
        Name              = "Sysprep" 
        location          = $location 
        Run               = './Sysprep.ps1'
    }
    Write-Host "Running the Sysprep custom script extension"
    Set-AzVMCustomScriptExtension @cseSettings | Out-Null
}
Catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ('Error running the Sysprep Custom Script Extension ' + $ErrorMessage)
    Break
}

#Deallocate the tempVM
#Wait for Sysprep to finish, status "VM stopped" the VM once finished
$displayStatus = ""
$count = 0
Try {
    while ($displayStatus -notlike "VM stopped") {
        Write-Host "Waiting for the VM display status to change to VM stopped"
        $displayStatus = (get-azvm -ErrorAction Stop -Name $capVmName -ResourceGroupName $refVmRg -Status).Statuses[1].DisplayStatus
        write-output "starting 15 second sleep"
        start-sleep -Seconds 15
        $count += 1
        if ($count -gt 11) {
            Write-Error "Three minute wait for VM to stop ended, canceling script.  Verify no updates are required on the source"
            Exit 
        }
    }
    Write-Host "Deallocating the VM and setting to Generalized"
    Stop-AzVM -ErrorAction Stop -ResourceGroupName $refVmRg -Name $capVmName -Force | Out-Null
    Set-AzVM -ErrorAction Stop -ResourceGroupName $refVmRg -Name $capVmName -Generalized | Out-Null
}
Catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ('Error deallocating the VM ' + $ErrorMessage)
    Break
}

# Create the image from the tempVM
# !!! Creation of managed images are not supported for virtual machine with TrustedLaunch security type.
Try {
    Write-Host "Capturing the VM image"
    $capVM = Get-AzVM -ErrorAction Stop -Name $capVmName -ResourceGroupName $refVmRg
    $vmGen = (Get-AzVM -ErrorAction Stop -Name $capVmName -ResourceGroupName $refVmRg -Status).HyperVGeneration
    #new-azgalleryimageversion -ResourceGroupName $CompGalNameRG -GalleryName $CompGalName -GalleryImageDefinitionName $galleryDef.Name -Name 1.1.0 -SourceImageVMId $capVm.Id -Location $location
    $image = New-AzImageConfig -ErrorAction Stop -Location $location -SourceVirtualMachineId $capVm.Id -HyperVGeneration $vmGen -Tag @{Name="PilotImage";Image="Pilot"}
    if ($galDeploy -eq $true) {
        Write-Host "Azure Compute Gallery used, saving image to the Compute Gallery Resource Group"
        $image = New-AzImage -Image $image -ImageName $imageName -ResourceGroupName $CompGalNameRG
    }
    elseif ($galDeploy -eq $false) {
        Write-Host "Azure Compute Gallery not used, saving image to the reference VM Resource Group"
        New-AzImage -Image $image -ImageName $imageName -ResourceGroupName $refVmRg | Out-Null
    }
    else {
        Write-Error 'Please set galDeploy to $true or $false'
    }
}
Catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ('Error creating the image ' + $ErrorMessage)
    Break
}

#Add image to the Azure Compute Gallery if that option was selected
Try {
    if ($galDeploy -eq $true) {
        Write-Host 'Adding image to the Azure Compute Gallery, this can take a few minutes'
        $imageSettings = @{
            ErrorAction                = 'Stop'
            ResourceGroupName          = $gallery.ResourceGroupName
            GalleryName                = $gallery.Name
            GalleryImageDefinitionName = $ImageDefName
            Name                       = $imageVersion
            Location                   = $gallery.Location
            SourceImageId              = $image.Id
        }
       $GalImageVer = New-AzGalleryImageVersion @imageSettings

       Write-Host "Image version $($GalImageVer.Name) added to the image definition"
    }
}
Catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ('Error adding the image to the Azure Compute Gallery ' + $ErrorMessage)
    Break
}

#Cleanup
#Remove image

if ($galDeploy -eq $true) {
    Write-Host "Azure Compute Gallery used, removing image from the Compute Gallery Resource Group"
    Remove-AzImage -ResourceGroupName $CompGalNameRG -ImageName $imageName -Force
}
else {
    Write-Host "Azure Compute Gallery not used, removing image from the reference VM Resource Group"
    Remove-AzImage -ResourceGroupName $refVmRg -ImageName $imageName -Force
}


#Remove the snapshot
#Removes reference computer snapshot if $delSnap is set to $true
if ($delSnap -eq $true) {
    Try {
        Write-Host "Removing the snapshot $($snapshot.Name)"
        Remove-AzSnapshot -ErrorAction Stop -ResourceGroupName $refVmRg -SnapshotName $snapshot.Name -Force | Out-Null
    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error removing the snapshot ' + $ErrorMessage)
        Break
    }
}

#Remove TempVM
if ($deltempvm -eq $true) {
    Try {
        Write-Host "Removing testVM $($capVmName)"
        Remove-AzVM -ErrorAction Stop -ResourceGroupName $refVmRg -Name $capVmName -Force | Out-Null
        Remove-AzDisk -ErrorAction Stop -ResourceGroupName $refVmRg -DiskName $osDisk.name -Force | Out-Null
        Remove-AzNetworkInterface -ErrorAction Stop -ResourceGroupName $refVmRg -Name $nic.name -Force | Out-Null
    }
    Catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ('Error deleting tempvm ' + $ErrorMessage)
        Break
    }
}
