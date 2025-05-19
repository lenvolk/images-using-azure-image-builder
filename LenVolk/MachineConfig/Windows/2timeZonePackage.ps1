
# !!! Uncomment the following lines to run the script in a fresh environment !!!

# # Start fresh - remove any previous attempts
# Remove-Module GuestConfiguration -ErrorAction SilentlyContinue
# Remove-Module ComputerManagementDsc -ErrorAction SilentlyContinue

# # Import the DSC resource module first (most important)
# Write-Host "Importing required modules..." -ForegroundColor Yellow
# Import-Module ComputerManagementDsc -Force -Verbose
# Import-Module GuestConfiguration -Force -Verbose

# # Get module versions for troubleshooting
# (Get-Module ComputerManagementDsc).Version
# (Get-Module GuestConfiguration).Version

# # Handle paths with absolute paths
$scriptDir = $PSScriptRoot ? $PSScriptRoot : "c:\Temp\BackUP\Temp\images-using-azure-image-builder\LenVolk\MachineConfig\Windows"
$configDir = Join-Path -Path $scriptDir -ChildPath "TimeZoneConfig"
$mofPath = Join-Path -Path $configDir -ChildPath "localhost.mof"

# # Make sure the MOF exists
# if (!(Test-Path -Path $mofPath)) {
#     Write-Error "MOF file not found at: $mofPath"
#     exit
# }

# Create the package in the output directory with minimal options
Write-Host "Creating Guest Configuration package..." -ForegroundColor Cyan
Set-Location -Path $configDir

New-GuestConfigurationPackage `
    -Name 'TimeZone' `
    -Configuration $mofPath `
    -Type 'AuditAndSet' `
    -Force `
    -Verbose

Write-Host "Package creation completed." -ForegroundColor Green