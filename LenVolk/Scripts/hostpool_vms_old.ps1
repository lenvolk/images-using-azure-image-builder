param(
  [CmdletBinding()]
  [parameter(Position=0)] [String]$Keyvaultname,
  [parameter(Position=1)] [String]$secretname
 
)

function LocateFile {
    param (
        [Parameter(mandatory = $true)]
        [string]$Name,
        [string]$SearchPath = '.',
        [switch]$Recurse
    )
    
    Write-Log -Message "Locating '$Name' within: '$SearchPath'"
    $Path = (Get-ChildItem "$SearchPath\" -Filter $Name -Recurse:$Recurse).FullName
    if ((-not $Path) -or (-not (Test-Path $Path))) {
        throw "'$Name' file not found at '$SearchPath'"
    }
    if (@($Path).Length -ne 1) {
        throw "Multiple '$Name' files found at '$SearchPath': [`n$Path`n]"
    }

    return $Path
}


function Write-Log {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        # note: can't use variable named '$Error': https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidAssignmentToAutomaticVariable.md
        [switch]$Err
    )
     
    try {
        $DateTime = Get-Date -Format "MM-dd-yy HH:mm:ss"
        $Invocation = "$($MyInvocation.MyCommand.Source):$($MyInvocation.ScriptLineNumber)"

        if ($Err) {
            $Message = "[ERROR] $Message"
        }
        
        Add-Content -Value "$DateTime - $Invocation - $Message" -Path "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\ScriptLog.log"
    }
    catch {
        throw [System.Exception]::new("Some error occurred while writing to log file with message: $Message", $PSItem.Exception)
    }
}

function InstallRDAgents {
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AgentInstallerFolder,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AgentBootServiceInstallerFolder,
    
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RegistrationToken,
    
        [Parameter(mandatory = $false)]
        [switch]$EnableVerboseMsiLogging
    )

    $ErrorActionPreference = "Stop"

    Write-Log -Message "Boot loader folder is $AgentBootServiceInstallerFolder"
    $AgentBootServiceInstaller = LocateFile -SearchPath $AgentBootServiceInstallerFolder -Name "*.msi"

    Write-Log -Message "Agent folder is $AgentInstallerFolder"
    $AgentInstaller = LocateFile -SearchPath $AgentInstallerFolder -Name "*.msi"

    if (!$RegistrationToken) {
        throw "No registration token specified"
    }

    RunMsiWithRetry -programDisplayName "RDAgentBootLoader" -isUninstall -argumentList @("/x {A38EE409-424D-4A0D-B5B6-5D66F20F62A5}", "/quiet", "/qn", "/norestart", "/passive") -msiOutputLogPath "C:\Users\AgentBootLoaderUnInstall.txt" -msiLogVerboseOutput:$EnableVerboseMsiLogging

    while ($true) {
        try {
            $oldAgent = Get-Package -ProviderName msi -Name "Remote Desktop Services Infrastructure Agent"
        }
        catch {
            #Ignore the error if it was due to no packages being found.
            if ($PSItem.FullyQualifiedErrorId -eq "NoMatchFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackage") {
                break
            }

            throw;
        }

        $oldVersion = $oldAgent.Version
        $productCodeParameter = $oldAgent.FastPackageReference

        RunMsiWithRetry -programDisplayName "RD Infra Agent $oldVersion" -isUninstall -argumentList @("/x $productCodeParameter", "/quiet", "/qn", "/norestart", "/passive") -msiOutputLogPath "C:\Users\AgentUninstall.txt" -msiLogVerboseOutput:$EnableVerboseMsiLogging
    }


    Write-Log -Message "Installing RD Infra Agent on VM $AgentInstaller"
    RunMsiWithRetry -programDisplayName "RD Infra Agent" -argumentList @("/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken") -msiOutputLogPath "C:\Users\AgentInstall.txt" -msiLogVerboseOutput:$EnableVerboseMsiLogging

    Write-Log -Message "Installing RDAgent BootLoader on VM $AgentBootServiceInstaller"
    RunMsiWithRetry -programDisplayName "RDAgent BootLoader" -argumentList @("/i $AgentBootServiceInstaller", "/quiet", "/qn", "/norestart", "/passive") -msiOutputLogPath "C:\Users\AgentBootLoaderInstall.txt" -msiLogVerboseOutput:$EnableVerboseMsiLogging

    $bootloaderServiceName = "RDAgentBootLoader"
    $startBootloaderRetryCount = 0
    while ( -not (Get-Service $bootloaderServiceName -ErrorAction SilentlyContinue)) {
        $retry = ($startBootloaderRetryCount -lt 6)
        $msgToWrite = "Service $bootloaderServiceName was not found. "
        if ($retry) { 
            $msgToWrite += "Retrying again in 30 seconds, this will be retry $startBootloaderRetryCount" 
            Write-Log -Message $msgToWrite
        } 
        else {
            $msgToWrite += "Retry limit exceeded" 
            Write-Log -Err $msgToWrite
            throw $msgToWrite
        }
            
        $startBootloaderRetryCount++
        Start-Sleep -Seconds 30
    }

    Write-Log -Message "Starting service $bootloaderServiceName"
    Start-Service $bootloaderServiceName
}


<# [CalledByARMTemplate] indirectly because this is called by InstallRDAgents #>
function RunMsiWithRetry {
    param(
        [Parameter(mandatory = $true)]
        [string]$programDisplayName,

        [Parameter(mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$argumentList, #Must have at least 1 value

        [Parameter(mandatory = $true)]
        [string]$msiOutputLogPath,

        [Parameter(mandatory = $false)]
        [switch]$isUninstall,

        [Parameter(mandatory = $false)]
        [switch]$msiLogVerboseOutput
    )
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    if ($msiLogVerboseOutput) {
        $argumentList += "/l*vx $msiOutputLogPath" 
    }
    else {
        $argumentList += "/l* $msiOutputLogPath"
    }

    $retryTimeToSleepInSec = 30
    $retryCount = 0
    $sts = $null
    do {
        $modeAndDisplayName = ($(if ($isUninstall) { "Uninstalling" } else { "Installing" }) + " $programDisplayName")

        if ($retryCount -gt 0) {
            Write-Log -Message "Retrying $modeAndDisplayName in $retryTimeToSleepInSec seconds because it failed with Exit code=$sts This will be retry number $retryCount"
            Start-Sleep -Seconds $retryTimeToSleepInSec
        }

        Write-Log -Message ( "$modeAndDisplayName" + $(if ($msiLogVerboseOutput) { " with verbose msi logging" } else { "" }))


        $processResult = Start-Process -FilePath "msiexec.exe" -ArgumentList $argumentList -Wait -Passthru
        $sts = $processResult.ExitCode

        $retryCount++
    } 
    while ($sts -eq 1618 -and $retryCount -lt 20) # Error code 1618 is ERROR_INSTALL_ALREADY_RUNNING see https://docs.microsoft.com/en-us/windows/win32/msi/-msiexecute-mutex .

    if ($sts -eq 1618) {
        Write-Log -Err "Stopping retries for $modeAndDisplayName. The last attempt failed with Exit code=$sts which is ERROR_INSTALL_ALREADY_RUNNING"
        throw "Stopping because $modeAndDisplayName finished with Exit code=$sts"
    }
    else {
        Write-Log -Message "$modeAndDisplayName finished with Exit code=$sts"
    }

    return $sts
} 

function ExtractDeploymentAgentZipFile {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string]$DeployAgentLocation
    )

    if (Test-Path $DeployAgentLocation) {
        Remove-Item -Path $DeployAgentLocation -Force -Confirm:$false -Recurse
    }
    
    New-Item -Path "$DeployAgentLocation" -ItemType directory -Force
    
    # Locating and extracting DeployAgent.zip
    $DeployAgentFromRepo = (LocateFile -Name 'DeployAgent.zip' -SearchPath $ScriptPath -Recurse)
    
    Write-Log -Message "Extracting 'Deployagent.zip' file into '$DeployAgentLocation' folder inside VM"
    Expand-Archive $DeployAgentFromRepo -DestinationPath "$DeployAgentLocation"
}

$ScriptPath = "C:\installers"
$ErrorActionPreference = "Stop"
Write-Log -Message "Creating a folder inside rdsh vm for extracting deployagent zip file"
$DeployAgentLocation = "C:\DeployAgent"
ExtractDeploymentAgentZipFile -ScriptPath $ScriptPath -DeployAgentLocation $DeployAgentLocation


Set-Location "$DeployAgentLocation"

# Checking if RDInfragent is registered or not in rdsh vm
$CheckRegistry = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

Write-Log -Message "Checking whether VM was Registered with RDInfraAgent"

if ($CheckRegistry)
{
    Write-Log -Message "VM was already registered with RDInfraAgent, script execution was stopped"
}
else
{
    Write-Log -Message "VM not registered with RDInfraAgent, script execution will continue"

    Write-Log "AgentInstaller is $DeployAgentLocation\RDAgentBootLoaderInstall, InfraInstaller is $DeployAgentLocation\RDInfraAgentInstall"
            $token=(Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net").access_token
            $hpkey = (Invoke-RestMethod -Headers @{"Authorization"="Bearer $token"} -Method GET -Uri "https://$($Keyvaultname).vault.azure.net//secrets/$($secretname)?api-version=2016-10-01").value


    InstallRDAgents -AgentBootServiceInstallerFolder "$DeployAgentLocation\RDAgentBootLoaderInstall" -AgentInstallerFolder "$DeployAgentLocation\RDInfraAgentInstall" -RegistrationToken $hpkey -EnableVerboseMsiLogging:$EnableVerboseMsiLogging

    Write-Log -Message "The agent installation code was successfully executed and RDAgentBootLoader, RDAgent installed inside VM for existing hostpool: $HostPoolName"
}




