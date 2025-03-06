# Script to detach and delete data disk (data01) from VM (Tools) in the Management subscription

# Parameters
$subscriptionName = "Management"
$resourceGroupName = "Bastion"
$vmName = "Tools"
$dataDiskName = "data01"

# Connect to the specific subscription
Write-Host "Connecting to subscription '$subscriptionName'..." -ForegroundColor Cyan
try {
    Select-AzSubscription -SubscriptionName $subscriptionName -ErrorAction Stop
    Write-Host "Successfully connected to subscription '$subscriptionName'" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to subscription '$subscriptionName'. Error: $_"
    exit 1
}

# Get the VM
Write-Host "Getting VM '$vmName' from resource group '$resourceGroupName'..." -ForegroundColor Cyan
try {
    $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -ErrorAction Stop
    Write-Host "Successfully retrieved VM '$vmName'" -ForegroundColor Green
}
catch {
    Write-Error "Failed to get VM '$vmName'. Error: $_"
    exit 1
}

# Find the data disk
Write-Host "Looking for data disk '$dataDiskName' on VM '$vmName'..." -ForegroundColor Cyan
$diskToRemove = $vm.StorageProfile.DataDisks | Where-Object { $_.Name -eq $dataDiskName }

if ($null -eq $diskToRemove) {
    Write-Error "Data disk '$dataDiskName' not found on VM '$vmName'"
    exit 1
}

# Get disk details before detaching
$diskId = $diskToRemove.ManagedDisk.Id
# Fixed: Use the correct parameter names for Get-AzDisk
try {
    # Extract the disk resource group from the ID if it's different from VM resource group
    $diskResourceGroup = $resourceGroupName
    if ($diskId -match "/resourceGroups/([^/]+)/") {
        $diskResourceGroup = $matches[1]
    }
    $disk = Get-AzDisk -ResourceGroupName $diskResourceGroup -DiskName $dataDiskName -ErrorAction Stop
    Write-Host "Found data disk '$dataDiskName' (LUN: $($diskToRemove.Lun))" -ForegroundColor Green
}
catch {
    Write-Error "Failed to retrieve disk details. Error: $_"
    # Continue anyway since we can still detach and delete the disk
    $disk = $null
}

# Confirm before proceeding
Write-Host "`nWARNING: You are about to detach and DELETE the following disk:" -ForegroundColor Yellow
Write-Host "Disk name: $dataDiskName" -ForegroundColor Yellow
if ($null -ne $disk) {
    Write-Host "Disk size: $($disk.DiskSizeGB) GB" -ForegroundColor Yellow
}
Write-Host "Disk ID: $diskId" -ForegroundColor Yellow

$confirmation = Read-Host "`nAre you sure you want to detach and DELETE this disk? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Operation cancelled by user." -ForegroundColor Cyan
    exit 0
}

# Detach data disk from VM
Write-Host "`nDetaching data disk '$dataDiskName' from VM '$vmName'..." -ForegroundColor Cyan
try {
    $vm = Remove-AzVMDataDisk -VM $vm -Name $dataDiskName
    Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm -ErrorAction Stop
    Write-Host "Successfully detached data disk '$dataDiskName' from VM '$vmName'" -ForegroundColor Green
}
catch {
    Write-Error "Failed to detach data disk. Error: $_"
    exit 1
}

# Delete the data disk
Write-Host "`nDeleting data disk '$dataDiskName'..." -ForegroundColor Cyan
try {
    # Use the extracted disk resource group
    $diskResourceGroup = $resourceGroupName
    if ($diskId -match "/resourceGroups/([^/]+)/") {
        $diskResourceGroup = $matches[1]
    }
    Remove-AzDisk -ResourceGroupName $diskResourceGroup -DiskName $dataDiskName -Force -ErrorAction Stop
    Write-Host "Successfully deleted data disk '$dataDiskName'" -ForegroundColor Green
}
catch {
    Write-Error "Failed to delete data disk. Error: $_"
    Write-Host "Note: The disk was detached, but not deleted. You will need to delete it manually." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nOperation completed successfully." -ForegroundColor Green
Write-Host "Data disk '$dataDiskName' has been detached from VM '$vmName' and deleted." -ForegroundColor Green
