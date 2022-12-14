# Installing Tools
#
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install
#
# We assume, that choco, the required PowerShell Azure Modules, the Azure CLI and VSCode are installed.
# Otherwise run this first:
#
# # Download and install chocolatey
# [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
# Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# # Install VSCode and Azure CLI
# choco install vscode -y
# choco install azure-cli -y
# # Install PowerShell Azure Modules Accounts & Resources
# Install-Module Az.Accounts
# Install-Module Az.Resources


# Install the VSCode Bicep extension

# Bicep CLI
# Self contained for az cli
az bicep install
az bicep upgrade
az bicep version


# Manual for PowerShell
bicep --version
choco install bicep -y
choco upgrade bicep -y
# Alternative options:https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually
bicep --version