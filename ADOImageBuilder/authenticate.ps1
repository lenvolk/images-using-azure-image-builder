# Install-Module -Name Az -AllowClobber -Force

Connect-AzAccount -Identity
Set-AzContext -Subscription "AVD"

az login --identity
az account set --subscription "AVD"
# az logout