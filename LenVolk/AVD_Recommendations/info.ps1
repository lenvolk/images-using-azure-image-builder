
# Ref
# https://techcommunity.microsoft.com/t5/azure-virtual-desktop-blog/curated-resiliency-recommendations-for-azure-virtual-desktop/ba-p/4122216
# Script
# https://azure.github.io/Azure-Proactive-Resiliency-Library-v2/tools/script-overviews/

Install-Module -Name ImportExcel -Force -SkipPublisherCheck
Install-Module -Name Az.ResourceGraph -SkipPublisherCheck
Install-Module -Name Az.Accounts -SkipPublisherCheck -Force

# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine

az login --only-show-errors -o table --query Dummy
# $subscription = "DemoSub"
# az account set -s Connectivity
# az logout

cd .\LenVolk\AVD_Recommendations

.\1_wara_collector.ps1 -TenantID 55c5efb8-a532-4676-b1c3-64406cee8104 -SubscriptionIds f043b87b-e870-4884-b2d1-d665cc58f247

.\2_wara_data_analyzer.ps1 -JSONFile .\WARA_File_2024-05-23_13_52.json