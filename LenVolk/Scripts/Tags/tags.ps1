#     Login to Azure first:
#             $subscription = "ca5dfa45-eb4e-4612-9ebd-06f6fc3bc996"
#             az logout
#             Login-AzAccount -Subscription $subscription 
#             Select-AzSubscription -Subscription $subscription 


$PathToCsv = "C:\Temp\BackUP\Temp\images-using-azure-image-builder\LenVolk\Scripts\Tags\computers.csv"
$computers = Get-Content -Path $PathToCsv

$tags = @{'PCI' = 'Yes'; 'Department'='Accounting'; 'Environment'='Dev'} 

# For Azure VMs
foreach ($vmName in $computers) { 
    # Write-Host ".... Assigning $tags to VM Name $computer "
    # Update-AzTag -Tag $tags -ResourceId "/subscriptions/<subID>/resourceGroups/<RGName>/providers/Microsoft.Compute/virtualMachines/$vmName" -Operation Merge -Verbose
    $vmAzure = Get-AzVM -Name $vmName
    if ($vmAzure) {
        Write-Output "$vmName VM updating Tags"
        Update-AzTag -ResourceId $vmAzure.Id -Operation Merge -Tag $tags

        if ($vmAzure.StorageProfile.OsDisk.ManagedDisk.Id) {
            Write-Output "> $vmName Disk $($vmAzure.StorageProfile.OsDisk.Name) updating Tags"
            Update-AzTag -ResourceId $vmAzure.StorageProfile.OsDisk.ManagedDisk.Id -Operation Merge -Tag $tags
        }

        foreach ($nic in $vmAzure.NetworkProfile.NetworkInterfaces) {
            Write-Output "> $vmName NIC updating Tags"
            Update-AzTag -ResourceId $nic.Id -Operation Merge -Tag $tags
        }
        foreach ($disk in $vmAzure.StorageProfile.DataDisks) {
            Write-Output "> $vmName Disk $($disk.Name) updating Tags"
            $azResource = Get-AzResource -Name "$($disk.Name)"
            Update-AzTag -ResourceId $azResource.Id -Operation Merge -Tag $tags
        }

    } else {
        Write-Output "$vmName VM not found"
    }
}

# For Azure ARC
# Install-Module Az.ConnectedMachine
# Get-AzConnectedMachine | fl
$RGName = "AzureARC"
foreach ($ArcName in $computers) { 
    $ArcMachine = Get-AzConnectedMachine -Name $ArcName -ResourceGroup $RGName
    if ($ArcMachine.Name) {
        Write-Output ""$ArcMachine.Name" VM updating Tags"
        Update-AzTag -ResourceId $ArcMachine.Id -Operation Merge -Tag $tags
    } 
    else {
        Write-Output "$ArcName VM not found"
        Add-Content -Path C:\temp\arc-not-found.txt -Value "$ArcName VM not found"
    }
}





# #Ref https://cloudrobots.net/2020/09/02/add-azure-vm-tags-w-powershell/

# # Set-VMTags.csv (example):

# # xbogus,BuiltBy:otto.helweg@cloudrobots.net,Application:Test,AppOwner:otto.helweg@cloudrobots.net,Account:123456
# # otto-test-linux,Owner:otto,needed-until-date:2020-12-31,environment:test
# # otto-test-linux-2,Owner:otto,needed-until-date:2020-12-31,environment:test
# # otto-test-win,Owner:otto,needed-until-date:2020-12-31,environment:test
# # otto-dev-win10,Owner:otto,needed-until-date:2021-12-31,environment:dev
# # Otto-MyWindows,Owner:otto,needed-until-date:2021-12-31,environment:dev

# <#
# .DESCRIPTION
#     Set tags for all VMs in a subscription
# .EXAMPLE
#     PS >> .\Set-VMMTags.ps1
# .NOTES
#     AUTHORS: Otto Helweg
#     LASTEDIT:September 2, 2020
#     VERSION: 1.0.3
#     POWERSHELL: Requires version 6
#     Update Execution Policy and Modules:
#         Set-ExecutionPolicy Bypass -Force
#     Login to Azure first:
#             Logout-AzAccount
#             Login-AzAccount -Subscription "<Azure Subscription>"
#             Select-AzSubscription -Subscription "<Azure Subscription>"
#     Example:
#         .\Set-VMTags.ps1 -Wait -inputFile "Set-VMTags.csv"
# #>

# param($inputFile)

# if (!($inputFile)) {
#     $inputFile = "Set-VMTags.csv"
# }

# $csvContent = Get-Content "./$inputFile"
# $vmList = @{}
# foreach ($item in $csvContent) {
#     $tags = @{}
#     $vmName,$vmTags = $item.Split(",")
#     if ($vmName -and $vmTags) {
#         $vmList[$vmName] = $vmTags
#         foreach ($tag in $vmTags) {
#             $tagData = $tag.Split(":")
#             $tags[$tagData[0]] = $tagData[1]
#         }

#         $vmAzure = Get-AzVM -Name "$vmName"

#         if ($vmAzure) {
#             Write-Output "$vmName VM updating Tags"
#             Update-AzTag -ResourceId $vmAzure.Id -Operation Merge -Tag $tags
#             foreach ($nic in $vmAzure.NetworkProfile.NetworkInterfaces) {
#                 Write-Output "> $vmName NIC updating Tags"
#                 Update-AzTag -ResourceId $nic.Id -Operation Merge -Tag $tags
#             }
#             if ($vmAzure.StorageProfile.OsDisk.ManagedDisk.Id) {
#                 Write-Output "> $vmName Disk $($vmAzure.StorageProfile.OsDisk.Name) updating Tags"
#                 Update-AzTag -ResourceId $vmAzure.StorageProfile.OsDisk.ManagedDisk.Id -Operation Merge -Tag $tags
#             }
#             foreach ($disk in $vmAzure.StorageProfile.DataDisks) {
#                 Write-Output "> $vmName Disk $($disk.Name) updating Tags"
#                 $azResource = Get-AzResource -Name "$($disk.Name)"
#                 Update-AzTag -ResourceId $azResource.Id -Operation Merge -Tag $tags
#             }

#             if ($Args -contains "-Wait") {
#                 Read-Host "Press Enter to continue"
#             }
#         } else {
#             Write-Output "$vmName VM not found"
#         }
#     } else {
#         Write-Output "Malformed tags"
#     }
# }