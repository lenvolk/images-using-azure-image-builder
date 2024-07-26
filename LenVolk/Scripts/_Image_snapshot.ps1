# $subscription = "DemoSub"
# PS 
# Connect-AzAccount -Subscription $subscription 
# Set-AzContext -Subscription $subscription
# Disconnect-AzAccount
#
# AZ CLI
## az cloud set --name AzureUSGovernment
## az cloud set --name AzureCloud
# az login --only-show-errors -o table --query Dummy
# az account set -s $Subscription
# az logout

# Reg: 
# https://github.com/tsrob50/WVD-Public/blob/master/SnapImage.ps1
# https://www.youtube.com/watch?v=H3UrVsI9f7s
#
# https://learn.microsoft.com/en-us/azure/virtual-desktop/create-custom-image-templates
# !!! No per User application install
#
# Image Builder by Vladimir https://github.com/vladimirshvetsfl/Azure/blob/main/PowerShell/imageBuilder/image_builder_avd.ps1
<#
.SYNOPSIS
    This script automates the process of creating an image of an Azure VM without destroying the source, or reference VM.
.DESCRIPTION
    This script automates the process of creating an image from an Azure VM without destroying it during the capture process.  
    At a high-level, the following steps are taken:
    Snapshot of source "reference" VM > create a temp "capture" Resource Group > Create an OS disk from snapshot > 
    create a VNet and VM in the capture RG > sysprep the VM with a Custom Script Extension > capture the VM >
    If using Azure Compute Gallery, add image to the gallery
    If not using Azure Compute Gallery, add image to reference VM Resource Group
    > remove capture Resource Group > remove snapshot

    *Requires the powershell AZ module
    *log into the target Azure subscription before running the script

.PARAMETER refVmName
    The name of the reference, or source VM used to build the image.

.PARAMETER refVmRg
    The name of the reference VM resource Group, also used for the location

.PARAMETER cseURI
    Optional, the URI for the Sysprep Custom Script Extension.  Default value is located on a public GitHub repo.  
    No guaranty on availability.  Recommend copying the file to your own location.  The file must be 
    publicly available.  Looking for something with more PowerShell Options?  Check out Image Builder.
    https://youtube.com/playlist?list=PLnWpsLZNgHzWeiHA_wG0xuaZMlk1Nag7E

.PARAMETER galDeploy
    Optional, indicates if the image will go to an Azure Compute Gallery.

.PARAMETER galName
    Required if -galDeploy is used.  The name of the Azure Compute Gallery.

.PARAMETER galDefName
    Required if -galDeploy is used.  The Image Definition name in the Azure Compute Gallery
    Be sure the hardware version (Gen1 or Gen2) match.
.PARAMETER delSnap
    Optional, indicates if the source snapshot of the reference computer will be 
    deleted as part of the cleanup process. 


.NOTES
    ## Script is offered as-is with no warranty, expressed or implied.  ##
    ## Test it before you trust it!                                     ##
    ## Please see the list below before running the script:             ##
    1. This script assumes the VM's, resource groups and Azure Compute Gallery, if used, are in the same region.
    2. If the script fails, you will need to manually clean up artifacts created (remove snapshot and capture Resource Group).
    3. Update the reference VM or disable updates.  Sysprep won't run with updates pending.
    4. The script will create a new, temporary "Capture" resource group and delete it once finished.
    5. The public IP and NSG is not required and can be commented out (update the NIC config also).  It's helpful for troubleshooting.

    Author      : Travis Roberts, Ciraltos llc
    Website     : www.ciraltos.com
    Version     : 1.0.0.0 Initial Build 3/12/2022

.EXAMPLE
    Create an image and add it to the source computers resource group:
    .\SnapImage.ps1 -refVmName "<ComputerName>" -refVmRg '<RGName>' -vnetRG 'IMAGEBUILDERRG' -vnetName 'aibVNet' -subnetName 'aibSubnet'

    Create an image and add it to an Azure Compute Gallery:
    .\_Image_snapshot.ps1 -refVmName 'ChocoWin11m365' -refVmRg 'IMAGEBUILDERRG' -galName 'aibSig' -galDefName 'ChocoWin11m365' -vnetName 'aibVNet' -subnetName 'aibSubnet'
#>
##########################################################################
# Get-AzVMImageSku -Location eastus2 -PublisherName MicrosoftWindowsDesktop -Offer office-365 | select Skus | Where-Object { $_.Skus -like 'win11*'}
# Get-AzVmImageSku -Location eastus2 -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-11'| Select Skus   #!!! Only the -avd are multi-session
# az vm image list --publisher MicrosoftWindowsDesktop --sku g2 --output table --all
##########################################################################

##########################################################################
# Creating marketplace vm (go to the script and change variables)
##########################################################################

#.\MarketPlaceVM.ps1
# .\ComputeGallery.ps1

##########################################################################
# Testing (marketplace Windows 11 Enterprise Multi-Session, Version 21H2 - Gen2)
$refVmName = 'GoldenWin11' 
$refVmRg = 'AVD-Image' 
$CompGalNameRG = 'CompGal' 
$CompGalName ='VolkCompGal'
$ImageDefName = 'Win11-O365'
$vnetRG = 'AVDNetWork'
$vnetName = 'AVDVNet' 
$subnetName = 'PooledHP'
$cseURI = 'https://raw.githubusercontent.com/lenvolk/images-using-azure-image-builder/main/LenVolk/Scripts/Sysprep.ps1'
$galDeploy = $true
$delSnap = $true
$deltempvm  = $true
$DiskSizeInGB = '127'

# [CmdletBinding()]
# param (
#     [Parameter(Mandatory = $true)][string]$refVmName,
#     [Parameter(Mandatory = $true)][string]$refVmRg,
#     [Parameter(Mandatory = $false)][string]$cseURI = 'https://raw.githubusercontent.com/lenvolk/images-using-azure-image-builder/main/LenVolk/Scripts/Sysprep.ps1',
#     [Parameter(Mandatory = $false)][switch]$galDeploy = $true,
#     [Parameter(Mandatory = $false)][string]$CompGalNameRG,
#     [parameter(Mandatory = $false)][string]$ImageDefName,
#     [parameter(Mandatory = $false)][string]$delSnap = $true,
#     [parameter(Mandatory = $false)][string]$deltempvm = $true,
#     [Parameter(Mandatory = $true)][string]$vnetRG,
#     [Parameter(Mandatory = $true)][string]$vnetName,
#     [Parameter(Mandatory = $true)][string]$subnetName,
#     [Parameter(Mandatory = $false)][string]$DiskSizeInGB
# )

##########################################################################
#Validate the Azure Compute Gallery settings were added correctly if used
##########################################################################
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
##########################################################################
#Set the date, used as unique ID for artifacts and image version  yyyyMMddHHmm
##########################################################################
$date = (get-date -Format yyyyMMddHHmm)
##########################################################################
#Set the image name, modify as needed
#Default based off reference computer name and date
$imageName = ($refVmName + 'Image' + $date)
##########################################################################
#Set the image version (Name)
#Used if adding the image to an Azure Compute Gallery
#Format is 0.yyyyMM.ddHHmm date format for the version to keep unique and increment each new image version
#$imageVersion = "2.0.0"
$imageVersion = '2.' + $date.Substring(0, 6) + '.' + $date.Substring(6, 6)
##########################################################################
#Disable breaking change warning message
Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value $true
##########################################################################
#Set the location, based on the reference computer resource group location
$location = (Get-AzResourceGroup -Name $refVmRg).Location
##########################################################################

##### Start Script #####
##########################################################################
#To avoid any confusions (since refVM is in the same RG as tempVM) let's shutdown reference VM - don't really have to do it
Stop-AzVM -ErrorAction Stop -ResourceGroupName $refVmRg -Name $refVmName  -Force | Out-Null
##########################################################################
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
##########################################################################
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
##########################################################################
# $SubnetId=(az network vnet subnet show --resource-group $vnetRG --vnet-name $vnetName --name=$subnetName --query id -o tsv)
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRG
$SubnetId = (Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet).id
##########################################################################
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
##########################################################################
#Create and start the tempVM
Try {
    Write-Host "Creating the temporary capture VM, this will take a couple minutes"
    $capVmName = ('tempVM' + $date) 
    $CapVmConfig = New-AzVMConfig -ErrorAction Stop -VMName $CapVmName -VMSize $vm.HardwareProfile.VmSize
    $capVm = Add-AzVMNetworkInterface -ErrorAction Stop -vm $CapVmConfig -id $nic.Id -DeleteOption "Delete"
    $capVm = Set-AzVMOSDisk -vm $CapVm -ManagedDiskId $osDisk.id -StorageAccountType Standard_LRS -DiskSizeInGB $DiskSizeInGB -CreateOption Attach -Windows -DeleteOption "Delete"
    $capVM = Set-AzVMBootDiagnostic -vm $CapVm -disable

    # Educational - Creation of managed images are not supported for virtual machine with TrustedLaunch security type
    # $capVM = Set-AzVmSecurityProfile -VM $capVM -SecurityType "TrustedLaunch" 
    # $capVM = Set-AzVmUefi -VM $capVM -EnableVtpm $true -EnableSecureBoot $true 

    $capVm = new-azVM -ResourceGroupName $refVmRg -Location $location -vm $capVm -DisableBginfoExtension -Tag @{Name="PilotImage";Image="Pilot"}
}
Catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ('Error creating the VM ' + $ErrorMessage)
    Break
}
##########################################################################
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
##########################################################################
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
##########################################################################
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
##########################################################################
# Create the image from the tempVM
# !!! Creation of managed images are not supported for virtual machine with TrustedLaunch security type.
Try {
    Write-Host "Capturing the VM image"
    $capVM = Get-AzVM -ErrorAction Stop -Name $capVmName -ResourceGroupName $refVmRg
    $vmGen = (Get-AzVM -ErrorAction Stop -Name $capVmName -ResourceGroupName $refVmRg -Status).HyperVGeneration
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
##########################################################################
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
##########################################################################
#                          Optional Cleanup                              #
##########################################################################
#Remove image
Remove-AzImage -ResourceGroupName $CompGalNameRG -ImageName $imageName -Force

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

# $Resources=(az resource list --tag 'Name=PilotImage' | ConvertFrom-Json)
# foreach($res in $Resources) {
#     #az resource delete -n $res.name -g $refVmRg --resource-type $res.type --verbose
#     Write-Host "Now deleting $res.name"
# }
#######################################
#         Test VMs creation           #
#######################################
# $refVmRg = 'imageBuilderRG' 
# $location = (Get-AzResourceGroup -Name $refVmRg).Location
# $vnetName = 'aibVNet' 
# $subnetName = 'aibSubnet'
$image = "/subscriptions/f043b87b-e870-4884-b2d1-d665cc58f247/resourceGroups/AVDCompGalRG/providers/Microsoft.Compute/galleries/AVDCompGal/images/Win10-O365/versions/2.0.0"
$VM_User = "aibadmin"
$WinVM_Password = "P@ssw0rdP@ssw0rd"

$VMIP=( az vm create --resource-group $refVmRg --name "pilotVM1" `
                    --admin-username $VM_User --admin-password $WinVM_Password `
                    --image $image --location $location --public-ip-sku Standard `
                    --size 'Standard_B2ms' --tags 'Name=PilotImage' `
                    --vnet-name $vnetName `
                    --subnet $subnetName `
                    --nsg '""' `
                    --query publicIpAddress -o tsv)

# $VMs = 5                    
# for ($vmno = 1 ; $vmno -le $VMs ; $vmno++) {
#     $VMname = "AVD-$Vnetno"
#     az vm create --resource-group $refVmRg --name $VMname `
#                     --admin-username $VM_User --admin-password $WinVM_Password `
#                     --image $image --location $location `
#                     --size 'Standard_B2ms' --tags 'Name=PilotImage' `
#                     --vnet-name $vnetName `
#                     --subnet $subnetName `
#                     --nsg '""' `
# }
##########################################################################
# Connect to VM
cmdkey /generic:$VMIP /user:$VM_User /pass:$WinVM_Password
mstsc /v:$VMIP /w:1440 /h:900

# # Delete
# az vm delete -n "pilotVM" -g $refVmRg --yes
# $Resources=(az resource list --tag 'Name=PilotImage' | ConvertFrom-Json)
# foreach($res in $Resources) {
#     az resource delete -n $res.name -g $refVmRg --resource-type $res.type --verbose
# }