$subscription = "c6aa1fdc-66a8-446e-8b37-7794cd545e44"
Connect-AzAccount -Subscription $subscription

$location = "eastus"
$rgName = "SIGRG"
$SIGName = "LabSIG"
$SIGDefName = "wvd-win10"
$ImageVer = "3.0.0"
#$region = "Central# US"

$SelectedImageVer = Get-AzGalleryImageVersion -ResourceGroupName $rgName -GalleryName $SIGName -GalleryImageDefinitionName $SIGDefName -Name $ImageVer
$galleryImageVersionID = $SelectedImageVer.Id

$diskName = "tmpOSDisk"
$imageOSDisk = @{Id = $galleryImageVersionID }
$OSDiskConfig = New-AzDiskConfig -Location $location -CreateOption "FromImage" -GalleryImageReference $imageOSDisk
$osd = New-AzDisk -ResourceGroupName $rgName -DiskName $diskName -Disk $OSDiskConfig

$sas = Grant-AzDiskAccess -ResourceGroupName $rgName -DiskName $osd.Name -Access "Read" -DurationInSecond 3600
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($sas.AccessSAS, "C:\Temp\_delete\myImg.vhd")

# Don't forget to delete the disk created above.
Revoke-AzDiskAccess -ResourceGroupName $rgName -DiskName $diskName
Remove-AzDisk -ResourceGroupName $rgName -DiskName $diskName -Force