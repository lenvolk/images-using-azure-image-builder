#Teams install script

# Param (        
#     [Parameter(Mandatory = $true)]
#     [string]$ProfilePath,
#     [string]$XMLSourceFolder
# )

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose

# Download the installer to the C:\temp directory
#invoke-webrequest -uri 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true' -OutFile 'c:\temp\Teams_windows_x64.msi'
# Install Teams
Start-Process -filepath msiexec.exe -Wait -ErrorAction Stop -ArgumentList '/i', 'C:\installers\teams\Teams_windows_x64.msi', '/l*v c:\temp\teams.log', 'ALLUSER=1'