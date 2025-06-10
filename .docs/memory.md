# Azure Resource Health Monitor Project

## Project Overview
Building a custom Azure Function solution to:
1. Review Azure services in subscription
2. Check authentication and prompt if needed
3. Allow subscription selection
4. Track resource regions in use
5. Monitor Azure Service Health for warnings/critical events
6. Filter alerts to only services currently in use
7. Run daily via scheduled Azure Function

## Requirements
- Azure Function with timer trigger (daily schedule)
- PowerShell runtime
- Managed Identity authentication
- Service Health API integration
- Resource inventory management
- Event filtering for relevant services only

## Deployment Parameters
- Resource Group Name: AzureCustomHealthStatus
- Deployment Region: canadacentral (changed from eastus due to quota issues)

## Architecture Components
- Azure Function App (PowerShell)
- Storage Account (for logs and state)  
- Key Vault (for configuration)
- Application Insights (monitoring)
- Managed Identity (authentication)

## Status
- ✅ DEPLOYMENT SUCCESSFUL! All infrastructure and code deployed to canadacentral
- ✅ Resource Group: AzureCustomHealthStatus created in Canada Central
- ✅ All Azure resources deployed successfully:
  - Function App: azure-health-monitor
  - Storage Account: stazurehealthmoni2ddk2u
  - Key Vault: kv-azurehea-2ddk2u2g
  - Application Insights: azure-health-monitor-insights
  - Managed Identity: azure-health-monitor-identity
  - App Service Plan: azure-health-monitor-plan
- ✅ PowerShell function code deployed successfully via Azure CLI
- ✅ Function scheduled to run daily at 8:00 AM UTC
- ✅ All role assignments and permissions configured

## Next Steps
1. Monitor function execution in Azure Portal
2. Check Application Insights for logs
3. Verify daily health reports in blob storage
4. Test manual function execution if needed

## Known Issues & Solutions
- Azure Developer CLI (azd) does not natively support PowerShell Azure Functions
- Deployment script automatically falls back to manual deployment (expected behavior)
- Updated Deploy.ps1 to use -TryAzd parameter (defaults to false) for better user experience
- Enhanced error handling for quota issues and regional availability

## Deployment Instructions
1. Navigate to the AzureHealthMonitor directory
2. Run the deployment script: .\Deploy.ps1 (uses manual deployment by default)
3. Or try azd with fallback: .\Deploy.ps1 -TryAzd $true
4. Follow troubleshooting guide in README.md if issues occur
