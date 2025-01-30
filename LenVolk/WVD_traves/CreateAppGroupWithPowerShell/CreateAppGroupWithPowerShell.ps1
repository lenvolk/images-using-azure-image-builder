# Install the Azure PowerShell Module
if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
      'Az modules installed at the same time is not supported.')
} else {
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}
# FROM:
# https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.5.0

# Verify the WVD Moduel is Installed
Get-InstalledModule -Name Az.Desk*

# Install the WVD module Only
Install-Module -Name Az.DesktopVirtualization

# Update the module
Update-Module Az.DesktopVirtualization


# Create and manage Application Groups
Connect-AzAccount
Get-AzSubscription
# Set subscription by Id
Set-AzContext -SubscriptionId "c6aa1fdc-66a8-446e-8b37-7794cd545e44"
# Set subscription by Name
Set-AzContext -SubscriptionName "AzIntConsumption"
# to validate
Get-AzContext

# Find and set the Host Pool ARM Path
Get-AzWvdHostPool -ResourceGroupName Lab1HPRG -HostPoolName Lab1HP | FL
$hostPoolArmPath = (Get-AzWvdHostPool -ResourceGroupName Lab1HPRG -HostPoolName Lab1HP).Id

# Create an Application Group
New-AzWvdApplicationGroup -Name "PowerShellLabAG" `
    -FriendlyName "PowerShellLabAG" `
    -ResourceGroupName "Lab1HPRG" `
    -ApplicationGroupType "RemoteApp" `
    -HostPoolArmPath $hostPoolArmPath `
    -Location EastUS

# Verify the Application Group
Get-AzWvdApplicationGroup

# Add the Desktop Virtualization User Role Assignment to a single user
New-AzRoleAssignment -SignInName "MarketingUser1@lvolk.com" `
    -RoleDefinitionName "Desktop Virtualization User" `
    -ResourceName "PowerShellLabAG" `
    -ResourceGroupName "Lab1HPRG" `
    -ResourceType "Microsoft.DesktopVirtualization/applicationGroups"

# Add the Desktop Virtualization User Role Assignment to a Group
# The Object ID is in the Azure Active Directory Group Properties
New-AzRoleAssignment -ObjectId "242865dd-4150-45c5-9659-12672862dc38" `
    -RoleDefinitionName "Desktop Virtualization User" `
    -ResourceName "PowerShellLabAG" `
    -ResourceGroupName "Lab1HPRG" `
    -ResourceType "Microsoft.DesktopVirtualization/applicationGroups"


# Verify Role Assignment
Get-AzRoleAssignment -ResourceGroupName "Lab1HPRG" `
    -ResourceName "PowerShellLabAG" `
    -ResourceType "Microsoft.DesktopVirtualization/applicationGroups" `
    -RoleDefinitionName "Desktop Virtualization User"

# Get the Start Menu Items 
Get-AzWvdStartMenuItem -ApplicationGroupName "PowerShellLabAG" -ResourceGroupName "Lab1HPRG" | Select-Object AppAlias,FilePath | Format-Table

# Add the Start Menu Application to the Application Group
New-AzWvdApplication -AppAlias "Paint" `
    -GroupName "PowerShellLabAG" `
    -Name "Paint" `
    -ResourceGroupName "Lab1HPRG" `
    -CommandLineSetting Allow

# Add a file based application to the Application Group
New-AzWvdApplication -GroupName "PowerShellLabAG" `
-Name "Perfmon" `
-ResourceGroupName "Lab1HPRG" `
-Filepath "C:\Windows\system32\perfmon.exe" `
-IconPath "C:\Windows\system32\perfmon.exe" `
-IconIndex "0" `
-CommandLineSetting Allow `
-ShowInPortal

# Verify Application Groups
Get-AzWvdApplication -GroupName "PowerShellLabAG" -ResourceGroupName "Lab1HPRG"

# Register the Application Group to a workspace
# Start by getting the Application Group path
Get-AzWvdApplicationGroup -ResourceGroupName "Lab1HPRG" -Name "PowerShellLabAG" | Format-List
# Assign the Application Group path to a variable
$appGroupPath = (Get-AzWvdApplicationGroup -ResourceGroupName "Lab1HPRG" -Name "PowerShellLabAG").Id

# Add the Application Group to the Workspace
Register-AzWvdApplicationGroup -ResourceGroupName "Lab1WSRG" `
    -WorkspaceName "Lab1WS" `
    -ApplicationGroupPath $appGroupPath
