# Log on to Azure 
Connect-AzAccount

# Verify connection to the correct subscription
Get-AzContext

<# Verify the commands are available
Expand-AzWvdMsixImage   
Get-AzWvdMsixPackage  
New-AzWvdMsixPackage    
Remove-AzWvdMsixPackage 
Update-AzWvdMsixPackage  #>
Get-Command -Module Az.DesktopVirtualization | Where-Object { $_.Name -match "MSIX" }

# If the module is not installed
Get-InstalledModule -Name "*desktop*"
Install-Module -Name Az.DesktopVirtualization -Force -AllowClobber

# if the module is outdated
Update-Module -Name Az.DesktopVirtualization -Force

# Set helper variables
# Set the subscription context
$obj = Get-AzContext
# Set the subscription ID
$subId = $obj.Subscription.Id
# Set the workspace name
$ws = "<WorksSpaceName>"
# Set the workspace resource group
$wsRg = "<WorkspaceResourceGroup>"
# Set the host pool name
$hp = "<HostPoolName>"
# Set the session host resource group
$rg = "<ResourceGroupName>"
# Verify the variables
Get-AzWvdWorkspace -Name $ws -ResourceGroupName $wsRg -SubscriptionId $subID
Get-AzWvdHostPool -Name $hp -ResourceGroupName $rg

# Add the MSIX Package to the host pool
# Set the UNC Path for the MSIX Image
$uncPath = "<UNCPath>"
# Set the application display name
$displayName = "<displayName>"
# Get the contents of the 
$obj = Expand-AzWvdMsixImage -HostPoolName $hp -ResourceGroupName $rg -SubscriptionId $subID -Uri $uncPath
# Add the MSIX Package to the Host Pool
New-AzWvdMsixPackage -HostPoolName $hp `
    -ResourceGroupName $rg `
    -SubscriptionId $subId `
    -PackageAlias $obj.PackageAlias `
    -DisplayName $displayName `
    -ImagePath $uncPath `
    -IsActive:$true
# Verify the App Attach application 
Get-AzWvdMsixPackage -ResourceGroupName $rg -HostPoolName $hp | FL

# Publish the MSIX App to a remote desktop application group
# Get the application groups
Get-AzWvdApplicationGroup -ResourceGroupName $rg -SubscriptionId $subId
# Set the application group
$grName = "<AppGroupName>"
# Assign the application to the desktop application group
New-AzWvdApplication -ResourceGroupName $rg `
    -SubscriptionId $subId `
    -Name $displayName `
    -ApplicationType MsixApplication `
    -GroupName $grName `
    -MsixPackageFamilyName $obj.PackageFamilyName `
    -CommandLineSetting 0
# Remove the application from the desktop application group
Remove-AzWvdApplication -ResourceGroupName $rg -Name $displayName -GroupName $grName

# Publish the MSIX App to a Remove App application group

# Create the applicaiton group
# set the application group name
$agName = '<Application Group Name>'
# Set the Object ID of the group
$wvdGroup = "<User Group Object ID>"
New-AzWvdApplicationGroup -ResourceGroupName $rg `
    -Name $agname `
    -Location (Get-AzResourceGroup $rg).location `
    -HostPoolArmPath "/subscriptions/$subId/resourcegroups/$rg/providers/Microsoft.DesktopVirtualization/hostPools/$hp" `
    -ApplicationGroupType 'RemoteApp'
# Verify application group
Get-AzWvdApplicationGroup -ResourceGroupName $rg -SubscriptionId $subId

# Add users to the new application group
New-AzRoleAssignment -ObjectId $wvdGroup `
    -RoleDefinitionName "Desktop Virtualization User" `
    -ResourceName $agName `
    -ResourceGroupName $rg `
    -ResourceType 'Microsoft.DesktopVirtualization/applicationGroups'

# Add the application group to the workspace
Update-AzWvdWorkspace -ResourceGroupName $wsRg `
    -Name $ws `
    -ApplicationGroupReference "/subscriptions/$subId/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/applicationGroups/$agName"
# Add MSIX Package to the remote app application group
New-AzWvdApplication -ResourceGroupName $rg `
    -SubscriptionId $subId `
    -Name $displayName `
    -ApplicationType MsixApplication `
    -GroupName $agName `
    -MsixPackageFamilyName $obj.PackageFamilyName `
    -CommandLineSetting 0 `
    -MsixPackageApplicationId $obj.PackageApplication.AppId

# Remove the MSIX Package
# Remove the remote app applicaiton group 
Remove-AzWvdApplicationGroup -ResourceGroupName $rg -Name $agName
# Get the MSIX Packages
Get-AzWvdMsixPackage -HostPoolName $hp -ResourceGroupName $rg -SubscriptionId $subId
# Remove the MSIX Package
Remove-AzWvdMsixPackage -FullName $obj.PackageFullName -HostPoolName $hp -ResourceGroupName $rg
