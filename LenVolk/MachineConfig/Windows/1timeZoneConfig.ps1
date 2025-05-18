
# Check if we're running in Windows PowerShell or PowerShell Core
if ($PSVersionTable.PSEdition -eq "Core") {
    Write-Warning "This script uses DSC which works best in Windows PowerShell. Consider running this in powershell.exe instead of pwsh.exe"
}

# Check if the module is installed
if (-not (Get-Module -Name ComputerManagementDsc -ListAvailable)) {
    Write-Host "Installing ComputerManagementDsc module..." -ForegroundColor Yellow
    Install-Module -Name ComputerManagementDsc -Force -Scope CurrentUser -AllowClobber
}

Write-Host "Importing module..." -ForegroundColor Yellow
Import-Module -Name ComputerManagementDsc -Force

Write-Host "Module path:" -ForegroundColor Green
(Get-Module -Name ComputerManagementDsc -ListAvailable).Path

# Define the configuration
Configuration TimeZoneCustom {
    # Import the DSC Resource
    Import-DscResource -ModuleName ComputerManagementDsc -Name TimeZone
    
    Node localhost {
        TimeZone TimeZoneConfig {
            TimeZone = 'Eastern Standard Time'
            IsSingleInstance = 'Yes'
        }
    }
}

# Create output directory in the Windows folder
# Handle case when PSScriptRoot is empty (running in console vs script)
if ($PSScriptRoot) {
    $basePath = $PSScriptRoot
} else {
    # Fallback to the Windows directory path
    $basePath = Join-Path -Path "c:\Temp\BackUP\Temp\images-using-azure-image-builder\LenVolk\MachineConfig" -ChildPath "Windows"
}

$outputPath = Join-Path -Path $basePath -ChildPath "TimeZoneConfig"
Write-Host "Creating output directory at: $outputPath" -ForegroundColor Cyan

if (!(Test-Path -Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# Generate the configuration
Write-Host "Generating DSC configuration..." -ForegroundColor Yellow
TimeZoneCustom -OutputPath $outputPath

# Check if MOF was created
if (Test-Path "$outputPath\localhost.mof") {
    Write-Host "Configuration created successfully!" -ForegroundColor Green
} else {
    Write-Host "Failed to create configuration." -ForegroundColor Red
}