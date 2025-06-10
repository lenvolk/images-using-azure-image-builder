# Quick Reference: How to Monitor Your Azure Health Monitor Function

## 🔍 Real-Time Monitoring Locations

### 1. **Application Insights Queries**
```bash
# Check function execution logs
az monitor app-insights query --app "385403b2-183c-4ac0-8f00-ca7ea23eff7a" --analytics-query "traces | where timestamp > ago(24h) and operation_Name == 'HealthMonitorFunction' | order by timestamp desc"

# Check resource inventory results
az monitor app-insights query --app "385403b2-183c-4ac0-8f00-ca7ea23eff7a" --analytics-query "traces | where timestamp > ago(24h) and message contains 'Found' and message contains 'resources' | order by timestamp desc"

# Check health events
az monitor app-insights query --app "385403b2-183c-4ac0-8f00-ca7ea23eff7a" --analytics-query "traces | where timestamp > ago(24h) and message contains 'health' | order by timestamp desc"
```

### 2. **Storage Account Monitoring**
```bash
# List all containers
az storage container list --account-name "stazurehealthmoni2ddk2u" --auth-mode login

# Check health reports (after first successful run)
az storage blob list --account-name "stazurehealthmoni2ddk2u" --container-name "health-reports" --auth-mode login

# Download latest report
az storage blob download --account-name "stazurehealthmoni2ddk2u" --container-name "health-reports" --name "health-report-{date}.json" --file "latest-report.json" --auth-mode login
```

### 3. **Function App Status**
```bash
# Check function app status
az functionapp show --name "azure-health-monitor" --resource-group "AzureCustomHealthStatus" --query "state"

# Check function app settings
az functionapp config appsettings list --name "azure-health-monitor" --resource-group "AzureCustomHealthStatus"
```

## 📋 **What Resources Are Being Monitored**

Based on our testing, your function monitors:
- **Total Resources**: 89+ Azure resources
- **Resource Types**: 23+ different types (VMs, Storage, Databases, etc.)
- **Regions**: 9 regions (canadacentral, eastus2, westus, northcentralus, swedencentral, switzerlandnorth, westus2, eastus, global)
- **Subscription**: LAB (64e4567b-012b-4966-9a91-b5c7c7b992de)

## 📧 **Email Notifications**
- **Status**: Enabled
- **Email**: lv@volk.bike
- **Trigger**: Only when health issues are detected

## ⏰ **Schedule**
- **Frequency**: Daily at 8:00 AM UTC
- **Next Run**: June 11, 2025 at 08:00:00 UTC

## 🛠️ **Azure Portal Links**

### Application Insights Dashboard:
https://portal.azure.com/#@{tenant}/resource/subscriptions/64e4567b-012b-4966-9a91-b5c7c7b992de/resourceGroups/AzureCustomHealthStatus/providers/microsoft.insights/components/azure-health-monitor-insights

### Storage Account:
https://portal.azure.com/#@{tenant}/resource/subscriptions/64e4567b-012b-4966-9a91-b5c7c7b992de/resourceGroups/AzureCustomHealthStatus/providers/Microsoft.Storage/storageAccounts/stazurehealthmoni2ddk2u

### Function App:
https://portal.azure.com/#@{tenant}/resource/subscriptions/64e4567b-012b-4966-9a91-b5c7c7b992de/resourceGroups/AzureCustomHealthStatus/providers/Microsoft.Web/sites/azure-health-monitor

## 🚨 **Troubleshooting Current Issue**

The function is currently failing due to missing PowerShell modules. This will be resolved on the next function restart when Azure Functions downloads the required modules specified in requirements.psd1.
