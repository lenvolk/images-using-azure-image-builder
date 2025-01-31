# Define the URL for the Chrome installer
$chromeUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
$chromeInstallerPath = "C:\Support\Logs\chrome_installer.exe"

# Create the folder if it doesn't exist
if (-not (Test-Path -Path "C:\Support\Logs")) {
    New-Item -ItemType Directory -Path "C:\Support\Logs"
}

# Download the Chrome installer
Invoke-WebRequest -Uri $chromeUrl -OutFile $chromeInstallerPath

# Silently install Chrome
Start-Process -FilePath $chromeInstallerPath -ArgumentList "/silent /install" -Wait