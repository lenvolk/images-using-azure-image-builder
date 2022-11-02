# T-Shooting
# https://learn.microsoft.com/en-us/azure/virtual-desktop/troubleshoot-agent?WT.mc_id=Portal-Microsoft_Azure_WVD

# $VmName = $env:computername | Select-Object
# mkdir -Path c:\ImageBuilder -name $VmName -erroraction silentlycontinue
# $HPRegToken | Out-File -FilePath c:\ImageBuilder\$VmName\$VmName.txt -Append

Param (
    [string]$HPRegToken
)


######################
#    AVD Variables   #
######################
$LocalAVDpath            = "c:\temp\avd\"
$AVDAgentURI             = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$AVDBootURI              = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$AVDAgentInstaller       = 'AVD-Agent.msi'
$AVDBootInstaller        = 'AVD-Bootloader.msi'
#$HPRegToken              = '<__param1__>'

####################################
#    Test/Create Temp Directory    #
####################################
New-Item -Path c:\ -Name New-AVDSessionHost.log -ItemType File
Add-Content `
-LiteralPath C:\New-AVDSessionHost.log `
"RegistrationToken = $HPRegToken"

if((Test-Path c:\temp) -eq $false) {
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Create C:\temp Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
    New-Item -Path c:\temp -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "C:\temp Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "temp directory already exists"
}
if((Test-Path $LocalAVDpath) -eq $false) {
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "Create C:\temp\AVD Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating c:\temp\AVD directory"
    New-Item -Path $LocalAVDpath -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\New-AVDSessionHost.log "C:\temp\AVD Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "c:\temp\AVD directory already exists"
}


#################################
#    Download AVD Componants    #
#################################
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Add-Content -LiteralPath C:\New-AVDSessionHost.log "Downloading AVD Agent"
    Invoke-WebRequest -Uri $AVDAgentURI -OutFile "$LocalAVDpath$AVDAgentInstaller"
Add-Content -LiteralPath C:\New-AVDSessionHost.log "Downloading AVD Boot Loader"
    Invoke-WebRequest -Uri $AVDBootURI -OutFile "$LocalAVDpath$AVDBootInstaller"

################################
#    Install AVD Componants    #
################################
# https://learn.microsoft.com/en-us/azure/virtual-desktop/create-host-pools-powershell?tabs=azure-powershell#update-the-agent

###
Add-Content -LiteralPath C:\New-AVDSessionHost.log "Installing AVD Bootloader"
$bootloader_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $LocalAVDpath$AVDBootInstaller", `
        "/quiet", `
        "/passive", `
        "/qn", `
        "/norestart", `
        "/l* $LocalAVDpath\AgentBootLoaderInstall.txt" `
    -Wait `
    -Passthru
$sts = $bootloader_deploy_status.ExitCode
Add-Content -LiteralPath C:\New-AVDSessionHost.log "Installing AVD Bootloader Complete"
Write-Output "Installing RDAgentBootLoader on VM Complete. Exit code=$sts`n"
Wait-Event -Timeout 5
###
Add-Content -LiteralPath C:\New-AVDSessionHost.log "Installing AVD Agent"
Write-Output "Installing RD Infra Agent on VM $AgentInstaller`n"
$agent_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $LocalAVDpath$AVDAgentInstaller", `
        "/quiet", `
        "/qn", `
        "/norestart", `
        "/passive", `
        "REGISTRATIONTOKEN=$HPRegToken", "/l* $LocalAVDpath\AgentInstall.txt" `
    -Wait `
    -Passthru
Add-Content -LiteralPath C:\New-AVDSessionHost.log "AVD Agent Install Complete"
Wait-Event -Timeout 5

Add-Content -LiteralPath C:\New-AVDSessionHost.log "Process Complete - REBOOT"
Restart-Computer -Force 