# Info https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds_vdi-recommendations-1909
# repo: https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
# TBD local policy settings https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds_vdi-recommendations-1909#local-policy-settings

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
###############################
#    Prep for WVD Optimize    #
###############################
Expand-Archive `
    -LiteralPath "C:\installers\Virtual-Desktop-Optimization-Tool.zip" `
    -DestinationPath "C:\installers\" `
    -Force `
    -Verbose
#################################
#    Run WVD Optimize Script    #
#################################
Set-Location -Path "C:\installers\Virtual-Desktop-Optimization-Tool"
OR
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#.\Windows_VDOT.ps1 -Optimizations All -Verbose -AcceptEula
Write-Output "Skipping optimization"