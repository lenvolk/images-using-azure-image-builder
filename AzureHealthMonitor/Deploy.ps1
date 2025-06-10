# Azure Health Monitor Deployment Script
# This script deploys the Azure Health Monitor solution

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "AzureCustomHealthStatus",
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory = $false)]
    [bool]$TryAzd = $false  # Default to manual deployment for PowerShell functions
)

Write-Host "=== Azure Health Monitor Deployment ===" -ForegroundColor Green

# Check if user is authenticated to Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Please authenticate to Azure first:" -ForegroundColor Yellow
        Write-Host "Connect-AzAccount" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "✓ Authenticated as: $($context.Account.Id)" -ForegroundColor Green
}
catch {
    Write-Host "Please install and authenticate Azure PowerShell:" -ForegroundColor Red
    Write-Host "Install-Module -Name Az -Scope CurrentUser -Force" -ForegroundColor Cyan
    Write-Host "Connect-AzAccount" -ForegroundColor Cyan
    exit 1
}

# Check if Azure CLI is available for function deployment
$azCliAvailable = $false
try {
    $azVersion = az version | ConvertFrom-Json
    if ($azVersion) {
        $azCliAvailable = $true
        Write-Host "✓ Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠ Azure CLI not found. Function deployment may require manual steps." -ForegroundColor Yellow
    Write-Host "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
}

# Email notification configuration
Write-Host "Email Notification Configuration:" -ForegroundColor Cyan
$enableEmail = Read-Host "Would you like to receive email notifications for health alerts? (y/N)"
$notificationEmail = ""

if ($enableEmail -match '^[Yy]') {
    do {
        $notificationEmail = Read-Host "Please enter your email address for notifications"
        
        # Validate email format
        $emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if ($notificationEmail -match $emailRegex) {
            Write-Host "✓ Email address validated: $notificationEmail" -ForegroundColor Green
            break
        } else {
            Write-Host "✗ Invalid email format. Please try again." -ForegroundColor Red
        }
    } while ($true)
    
    Write-Host "✓ Email notifications will be configured" -ForegroundColor Green
} else {
    Write-Host "✓ Email notifications disabled" -ForegroundColor Green
}

Write-Host ""

# Display deployment information
Write-Host ""
Write-Host "Deployment Configuration:" -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  Location: $Location" -ForegroundColor White
Write-Host "  Subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor White
Write-Host "  Method: $(if ($TryAzd) { 'Azure Developer CLI (with fallback)' } else { 'Manual deployment' })" -ForegroundColor White
Write-Host "  Email Notifications: $(if ($notificationEmail) { "Enabled ($notificationEmail)" } else { 'Disabled' })" -ForegroundColor White
Write-Host ""

# Note about PowerShell functions and azd
if ($TryAzd) {
    Write-Host "Note: Azure Developer CLI does not natively support PowerShell Azure Functions." -ForegroundColor Yellow
    Write-Host "This deployment will attempt azd but will fall back to manual deployment." -ForegroundColor Yellow
    Write-Host ""
}

# Confirm deployment
$confirm = Read-Host "Do you want to proceed with the deployment? (y/N)"
if ($confirm -notmatch '^[Yy]') {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

try {
    $useManualDeployment = $true
    
    # Try azd deployment if requested
    if ($TryAzd) {
        Write-Host "Attempting deployment with Azure Developer CLI..." -ForegroundColor Cyan
        
        # Check if azd is installed
        if (Get-Command azd -ErrorAction SilentlyContinue) {
            try {
                # Initialize azd if needed
                if (-not (Test-Path ".azure")) {
                    Write-Host "Initializing azd environment..." -ForegroundColor Yellow
                    azd init --environment production
                }
                
                # Set environment variables
                azd env set AZURE_LOCATION $Location
                azd env set AZURE_RESOURCE_GROUP_NAME $ResourceGroupName
                
                # Deploy with azd
                Write-Host "Running azd up..." -ForegroundColor Yellow
                azd up --environment production
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ Deployment completed successfully using azd!" -ForegroundColor Green
                    $useManualDeployment = $false
                } else {
                    Write-Host "✗ AZD deployment failed! Falling back to manual deployment..." -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "✗ AZD deployment error: $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Host "Falling back to manual deployment..." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Azure Developer CLI (azd) is not installed." -ForegroundColor Yellow
            Write-Host "Install from: https://aka.ms/azd-install" -ForegroundColor Yellow
            Write-Host "Falling back to manual deployment..." -ForegroundColor Yellow
        }
    }
    
    # Manual deployment
    if ($useManualDeployment) {
        Write-Host "Deploying using Azure PowerShell and CLI..." -ForegroundColor Cyan
        
        # Create resource group if it doesn't exist
        $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        if (-not $rg) {
            Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
            Write-Host "✓ Resource group created" -ForegroundColor Green
        } else {
            Write-Host "✓ Resource group exists: $ResourceGroupName" -ForegroundColor Green
        }
          # Deploy infrastructure
        Write-Host "Deploying infrastructure with Bicep..." -ForegroundColor Yellow
        
        # Prepare deployment parameters
        $deploymentParams = @{
            ResourceGroupName = $ResourceGroupName
            TemplateFile = "infra/main.bicep"
            TemplateParameterFile = "infra/main.parameters.json"
            location = $Location
            Verbose = $true
        }
        
        # Add email notification parameters if email is configured
        if (![string]::IsNullOrEmpty($notificationEmail)) {
            $deploymentParams.Add('notificationEmail', $notificationEmail)
            $deploymentParams.Add('emailNotificationsEnabled', $true)
            Write-Host "✓ Email notifications will be configured for: $notificationEmail" -ForegroundColor Green
        } else {
            $deploymentParams.Add('emailNotificationsEnabled', $false)
            Write-Host "✓ Email notifications disabled" -ForegroundColor Green
        }
        
        $deployment = New-AzResourceGroupDeployment @deploymentParams
        
        if ($deployment.ProvisioningState -eq "Succeeded") {
            Write-Host "✓ Infrastructure deployed successfully" -ForegroundColor Green
            
            # Get function app name from outputs
            $functionAppName = $deployment.Outputs.functionAppName.Value
            $storageAccountName = $deployment.Outputs.storageAccountName.Value
            
            Write-Host "Function App: $functionAppName" -ForegroundColor Cyan
            Write-Host "Storage Account: $storageAccountName" -ForegroundColor Cyan
            
            # Deploy function code if Azure CLI is available
            if ($azCliAvailable) {
                Write-Host "Packaging function code..." -ForegroundColor Yellow
                $packagePath = "function-package.zip"
                
                if (Test-Path $packagePath) {
                    Remove-Item $packagePath -Force
                }
                
                # Create zip package
                Compress-Archive -Path "src/*" -DestinationPath $packagePath -Force
                
                Write-Host "Deploying function code..." -ForegroundColor Yellow
                
                # Deploy using Azure CLI
                $deployResult = az functionapp deployment source config-zip `
                    --resource-group $ResourceGroupName `
                    --name $functionAppName `
                    --src $packagePath 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ Function code deployed successfully" -ForegroundColor Green
                    Remove-Item $packagePath -Force
                } else {
                    Write-Host "⚠ Function code deployment encountered issues:" -ForegroundColor Yellow
                    Write-Host $deployResult -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "You can manually deploy the function code:" -ForegroundColor Yellow
                    Write-Host "1. Go to the Azure portal" -ForegroundColor White
                    Write-Host "2. Navigate to Function App: $functionAppName" -ForegroundColor White
                    Write-Host "3. Use the Deployment Center to upload the 'src' folder" -ForegroundColor White
                }
            } else {
                Write-Host "⚠ Skipping function code deployment (Azure CLI not available)" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "To deploy the function code manually:" -ForegroundColor Yellow
                Write-Host "1. Go to the Azure portal" -ForegroundColor White
                Write-Host "2. Navigate to Function App: $functionAppName" -ForegroundColor White
                Write-Host "3. Use the Deployment Center to upload the 'src' folder" -ForegroundColor White
            }
        } else {
            Write-Host "✗ Infrastructure deployment failed" -ForegroundColor Red
            
            # Check for common issues
            if ($deployment.Error -and $deployment.Error.ToString() -match "quota|limit") {
                Write-Host ""
                Write-Host "This appears to be a quota/limit issue. Try:" -ForegroundColor Yellow
                Write-Host "1. Choose a different Azure region" -ForegroundColor White
                Write-Host "2. Use a different subscription" -ForegroundColor White
                Write-Host "3. Request a quota increase from Microsoft" -ForegroundColor White
                Write-Host ""
                Write-Host "Available regions for your subscription:" -ForegroundColor Cyan
                $availableLocations = (Get-AzLocation | Where-Object { $_.Providers -contains "Microsoft.Web" } | Select-Object -First 10).Location
                $availableLocations | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
            }
            
            Write-Host ""
            Write-Host "Error details:" -ForegroundColor Red
            Write-Host $deployment.Error -ForegroundColor Red
            exit 1
        }
    }
    
    # Final success message
    Write-Host ""
    Write-Host "=== Deployment Summary ===" -ForegroundColor Green
    Write-Host "✓ Azure Health Monitor deployed successfully!" -ForegroundColor Green
    Write-Host "✓ Function will run daily at 8:00 AM UTC" -ForegroundColor Green
    Write-Host "✓ Monitoring subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Check the function execution in the Azure portal" -ForegroundColor White
    Write-Host "2. Review Application Insights for detailed logs" -ForegroundColor White
    Write-Host "3. Monitor blob storage for daily health reports" -ForegroundColor White
    Write-Host "4. Customize alert notifications if needed" -ForegroundColor White
    Write-Host ""
    Write-Host "Azure Portal: https://portal.azure.com" -ForegroundColor Yellow
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
    Write-Host "Location: $Location" -ForegroundColor Yellow
}
catch {
    Write-Host "✗ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Ensure you have the required permissions in the subscription" -ForegroundColor White
    Write-Host "2. Check if the resource group name is available" -ForegroundColor White
    Write-Host "3. Try a different Azure region" -ForegroundColor White
    Write-Host "4. Verify Azure PowerShell and CLI are properly installed" -ForegroundColor White
    Write-Host ""
    Write-Host "For detailed error information:" -ForegroundColor Gray
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}
