
#region Create virtual disk
# Enable Hyper-V 
# Requires a restart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All 

# Create the Virtual Disk
# Set the path and name of the disk
# use a .vhdx disk type
$vDisk = "C:\Temp\7ZipMSIX.vhdx" #"<Path and name of virtual disk>"
New-VHD -SizeBytes 2096MB -Path $vDisk -Dynamic -Confirm:$false

# Mount the virtual disk
$vhdObject = Mount-VHD $vDisk -Passthru

# Initialize the virtual disk
$disk = Initialize-Disk -Passthru -Number $vhdObject.Number

# Partition the virtual disk
$partition = New-Partition -AssignDriveLetter -UseMaximumSize -DiskNumber $disk.Number

# Format the partition
Format-Volume -FileSystem NTFS -Confirm:$false -DriveLetter $partition.DriveLetter -Force

# Create a parent folder in the root of the new partition
# Record for later
$parentFolder = "msix"
$driveLetter = ($partition.DriveLetter).ToString() + ':\'
$unpackDir = New-Item  -Path $driveLetter -Name $parentFolder -ItemType Directory

# Run mountvol and get the volume ID of the virtual disk
# record for later
$volumeGuid = "<Volume GUID>"

#endregion

#region Extract MSIX
# Download the msixmgr tool
# https://aka.ms/msixmgr

# Path to the source MSIX package
$msixSource = "<Path to MSIX Package>"
cd C:\Temp\msixmgr\x64
.\msixmgr.exe -Unpack -packagePath $msixSource -destination $unpackDir -applyacls

# Get the full package name from the unpacked files
$packageName = "<Full Package Name>" 

# Unmount VHC
$vhdObject | Dismount-VHD

#endregion


### Test the App Attach package with the four stage and register scripts ###


#region Mount the storage account and upload the VHD

# Connect to Azure if not already
Connect-AzAccount

# Set variables for the storage account
$resourceGroupName = "<Storage Account Resource Group>"
$storageAccountName = "<Storage Account Name>"
$shareName = "<Share Name>"

# Get the storage account key
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]

#  Run the code below to test the connection and mount the share
$connectTestResult = Test-NetConnection -ComputerName "$storageAccountName.file.core.windows.net" -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    net use T: "\\$storageAccountName.file.core.windows.net\$shareName" /user:Azure\$storageAccountName $storageAccountKey
} 
else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN,   Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

# Disconnect the Storage Account when finished
net use T: /delete


#endregion

