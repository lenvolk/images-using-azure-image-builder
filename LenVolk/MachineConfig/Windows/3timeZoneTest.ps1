# Ensure required modules are imported
Import-Module ComputerManagementDsc -Force
Import-Module GuestConfiguration -Force


# Set-TimeZone -Id "Pacific Standard Time"

# Test Get function - This runs the Get() and Test() methods in your DSC resource
Get-GuestConfigurationPackageComplianceStatus .\TimeZone.zip -Verbose

# Test Set function - This runs the Set() method in your DSC resource if Test() reported non-compliant
Start-GuestConfigurationPackageRemediation .\TimeZone.zip -Verbose

