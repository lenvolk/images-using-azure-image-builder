# =================================================================================================
# Set Environment for Deployment
# =================================================================================================
Write-Host "Getting Azure Cloud list..." -ForegroundColor Yellow
$CloudList = (Get-AzEnvironment).Name
Write-Host "Which Azure Cloud would you like to deploy to?"
Foreach($cloud in $CloudList){Write-Host ($CloudList.IndexOf($cloud)+1) "-" $cloud}
$select = Read-Host "Enter selection"
$Environment = $CloudList[$select-1]
Write-Host "Connecting to Azure... (Look for minimized or hidden window)" -ForegroundColor Yellow
Connect-AzAccount -Environment $Environment | Out-Null
Clear-Host


# =================================================================================================
# Set Tenant for Deployment
# =================================================================================================
[array]$Tenants = Get-AzTenant
If ($Tenants.count -gt 1){
    Write-Host "Which Azure Tenant would you like to deploy to?"
    Foreach($Tenant in $Tenants){
        Write-Host ($Tenants.Indexof($Tenant)+1) "-" $Tenant.Name
    }
    $TenantSelection = Read-Host "Enter selection"
    $TenantId = ($Tenants[$TenantSelection-1]).Id
    Clear-Host
}
else{$TenantId = $Tenants[0].Id}

# =================================================================================================
# Set Subscription for Deployment
# =================================================================================================
# Write-Host "Which Azure Subscription would you like to deploy the VMs to?"
# [array]$Subs = Get-AzSubscription -TenantId $TenantId
# Foreach($Sub in $Subs){
#     Write-Host ($Subs.Indexof($Sub)+1) "-" $Sub.Name
#  }
# $SubSelection = Read-Host "Enter selection"
# $SubID = ($Subs[$SubSelection-1]).Id
# Set-AzContext -Tenant $TenantId -Subscription $SubID | Out-Null
# Clear-Host

