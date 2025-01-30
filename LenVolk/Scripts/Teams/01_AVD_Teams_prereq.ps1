#Teams prereq install script
# location of teams "redirections.xml" should be placed in the share

# Param (        
#     [Parameter(Mandatory = $true)]
#     [string]$ProfilePath,
#     [string]$XMLSourceFolder
# )

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
#set-location C:\installers\teams
# Set FSLogix share

# Create a temp folder for downloads
# if (!(Test-Path "c:\temp")) {
#     New-Item -Type Directory -Path 'c:\' -Name "temp"
# }


# Install the WebRTC redirect service
#invoke-webrequest -uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt' -OutFile 'c:\temp\MsRdcWebRTCSvc_x64.msi'
Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i C:\installers\teams\MsRdcWebRTCSvc_x64.msi /quiet /norestart'


# Install the Visual Studio C++ service
# !!! that requires reboot !!!
#invoke-webrequest -uri 'https://aka.ms/vs/16/release/vc_redist.x64.exe' -OutFile 'c:\temp\VC_redist.x64.exe'
Start-Process -filepath "C:\installers\teams\VC_redist.x64.exe"   -Wait -ErrorAction Stop -ArgumentList '/quiet /norestart /log C:\installers\teamsVC_redist.log'
