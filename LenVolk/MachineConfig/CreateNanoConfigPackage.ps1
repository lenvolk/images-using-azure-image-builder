# Script to package your DSC configuration for Azure Machine Configuration

# --- Prerequisites ---
Write-Host "Checking for and installing prerequisite modules (PSDscResources, GuestConfiguration)..."
Install-Module -Name PSDscResources -Scope CurrentUser -Force -ErrorAction SilentlyContinue
Install-Module -Name GuestConfiguration -Scope CurrentUser -Force -ErrorAction SilentlyContinue

# --- Adjust PSModulePath to help DSC find modules ---
$winPsModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "WindowsPowerShell\Modules"
$corePsModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "PowerShell\Modules"

if (Test-Path $winPsModulePath -PathType Container -ErrorAction SilentlyContinue) {
    if ($env:PSModulePath -notlike "*$winPsModulePath*") {
        $env:PSModulePath = "$winPsModulePath;$env:PSModulePath"
        Write-Verbose "Added Windows PowerShell CurrentUser module path to PSModulePath for this session."
    }
}
if (Test-Path $corePsModulePath -PathType Container -ErrorAction SilentlyContinue) {
    if ($env:PSModulePath -notlike "*$corePsModulePath*") {
        $env:PSModulePath = "$corePsModulePath;$env:PSModulePath"
        Write-Verbose "Added PowerShell Core CurrentUser module path to PSModulePath for this session."
    }
}
# Also ensure system paths are there - $env:PSModulePath can sometimes be incomplete in scripts
$systemModulePath = "C:\Program Files\WindowsPowerShell\Modules" # Common AllUsers path
if (Test-Path $systemModulePath -PathType Container -ErrorAction SilentlyContinue){
    if ($env:PSModulePath -notlike "*$systemModulePath*") {
        $env:PSModulePath = "$systemModulePath;$env:PSModulePath"
        Write-Verbose "Added System module path to PSModulePath for this session."
    }
}


# Import the GuestConfiguration and PSDscResources modules explicitly in this session
try {
    Import-Module GuestConfiguration -Force -ErrorAction Stop
    Import-Module PSDscResources -Force -ErrorAction Stop # Explicitly import PSDscResources
} catch {
    Write-Error "Failed to import required modules (GuestConfiguration, PSDscResources). Please ensure they are installed correctly."
    Write-Error "You can install them by running: "
    Write-Error "  Install-Module -Name GuestConfiguration -Scope CurrentUser -Force"
    Write-Error "  Install-Module -Name PSDscResources -Scope CurrentUser -Force"
    Write-Error "Original error: $($_.Exception.Message)"
    exit 1
}

# --- Configuration Settings ---
$DscConfigurationScriptPath = "C:\Temp\BackUP\Temp\images-using-azure-image-builder\LenVolk\MachineConfig\EnsureNanoNotInstalled.ps1" # <--- UPDATE THIS PATH if needed
$BaseWorkingDir = "C:\Temp\BackUP\Temp\images-using-azure-image-builder\LenVolk\MachineConfig\Output"
$MofStagingDir = Join-Path -Path $BaseWorkingDir -ChildPath "MofStaging"
New-Item -Path $BaseWorkingDir -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path $MofStagingDir -ItemType Directory -Force -ErrorAction SilentlyContinue

$PackageBaseName = "RHEL_EnsureNanoNotInstalled"
$DscConfigurationName = "EnsureNanoNotInstalled"

if (-not (Test-Path $DscConfigurationScriptPath)) {
    Write-Error "DSC Configuration script not found at: $DscConfigurationScriptPath"
    exit 1
}

# --- Compile the DSC Configuration to MOF ---
Write-Host "Compiling DSC Configuration to MOF (Configuration: '$DscConfigurationName')..."
$CompilationError = $null
try {
    . $DscConfigurationScriptPath # Dot-source to load the configuration definition

    # Invoke the configuration directly to produce the MOF.
    # The configuration name becomes a command after dot-sourcing.
    & $DscConfigurationName -OutputPath $MofStagingDir -Verbose

    $CompiledMofPath = Join-Path -Path $MofStagingDir -ChildPath $DscConfigurationName -ChildPath "localhost.mof"

    if (-not (Test-Path $CompiledMofPath)) {
        $CompiledMofPath = Join-Path -Path $MofStagingDir -ChildPath "localhost.mof" # Fallback check
        if (-not (Test-Path $CompiledMofPath)) {
            Write-Error "Failed to compile DSC configuration. MOF file not found at expected locations:"
            Write-Error "  - $MofStagingDir\$DscConfigurationName\localhost.mof"
            Write-Error "  - $MofStagingDir\localhost.mof"
            Write-Error "Please check the DSC script '$DscConfigurationScriptPath' for syntax errors."
            Write-Error "Ensure PSDscResources module is installed in a location discoverable by the DSC engine (see previous advice)."
            # Attempt to capture the actual DSC engine error if available in the $Error stack
            $dscError = $Error | Where-Object {$_.Exception.Message -like "*Import-DSCResource*" -or $_.Exception.Message -like "*Undefined DSC Resource*"} | Select-Object -First 1
            if ($dscError) {
                Write-Error "Underlying DSC Engine Error: $($dscError.Exception.Message)"
            }
            exit 1
        }
    }
    Write-Host "DSC Configuration compiled successfully: $CompiledMofPath" -ForegroundColor Green

} catch {
    $CompilationError = $_
    Write-Error "An error occurred during DSC compilation: $($CompilationError.Exception.Message)"
    Write-Error "Script: $($CompilationError.InvocationInfo.ScriptLineNumber) - $($CompilationError.InvocationInfo.Line)"
    Write-Warning "Ensure the DSC configuration script '$DscConfigurationScriptPath' is correctly formatted."
    Write-Warning "Ensure PSDscResources (for nxPackage) is installed and accessible by the DSC engine."
    Write-Warning "Consider installing PSDscResources via a Windows PowerShell 5.1 console or with '-Scope AllUsers' (admin) if you suspect module path issues."
    exit 1
}

# --- Create the Guest Configuration Package ---
# (Rest of the script remains the same as your previous working version for packaging)
Write-Host "Creating Guest Configuration package from MOF..."
$PackageStagingPath = Join-Path -Path $BaseWorkingDir -ChildPath "PackageStaging_$(Get-Date -Format 'yyyyMMddHHmmss')"

try {
    $PackageParameters = @{
        Name          = $PackageBaseName
        Configuration = $CompiledMofPath
        Path          = $PackageStagingPath
        Verbose       = $true
    }
    $null = New-GuestConfigurationPackage @PackageParameters

    $ExpectedPackageFile = Join-Path -Path $PackageStagingPath -ChildPath "$PackageBaseName.zip"

    if (Test-Path $ExpectedPackageFile) {
        $FinalPackagePath = Join-Path -Path $BaseWorkingDir -ChildPath "$PackageBaseName.zip"
        Move-Item -Path $ExpectedPackageFile -Destination $FinalPackagePath -Force
        Write-Host "Guest Configuration package created successfully: $FinalPackagePath" -ForegroundColor Green

        Write-Host "Calculating SHA256 hash for the package..."
        $FileHash = Get-FileHash -Path $FinalPackagePath -Algorithm SHA256
        $ContentHash = $FileHash.Hash.ToUpper()

        Write-Host "`n--- Values for Azure Portal (as per your screenshot) ---" -ForegroundColor Yellow
        Write-Host "1. Upload the package '$FinalPackagePath' to Azure Blob Storage (or any HTTPS accessible location)."
        Write-Host "2. Get the Blob SAS URI (or public HTTPS URI) for the uploaded package. This is your 'Content URI'."
        Write-Host "3. Content hash (SHA256): $ContentHash"
        Write-Host "4. Type: Audit (or 'DeployIfNotExists')"
        Write-Host "---------------------------------------------------------" -ForegroundColor Yellow
    } else {
        Write-Error "Failed to find the created package at $ExpectedPackageFile. Check for errors from New-GuestConfigurationPackage above."
    }

} catch {
    Write-Error "An error occurred during packaging: $($_.Exception.Message)"
} finally {
    if (Test-Path $PackageStagingPath) {
        Remove-Item -Path $PackageStagingPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    # You might want to keep $MofStagingDir for debugging, or remove it:
    # if (Test-Path $MofStagingDir) { Remove-Item -Path $MofStagingDir -Recurse -Force -ErrorAction SilentlyContinue }
}