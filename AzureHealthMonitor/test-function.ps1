# Test script to run the health monitor function locally
# This will help us test the email notification functionality

# Set up test environment variables
$env:STORAGE_ACCOUNT_NAME = "stazurehealthmoni2ddk2u"
$env:KEY_VAULT_NAME = "kv-azurehea-2ddk2u2g"
$env:PREFERRED_SUBSCRIPTION_ID = "64e4567b-012b-4966-9a91-b5c7c7b992de"
$env:EMAIL_NOTIFICATIONS_ENABLED = "True"
$env:NOTIFICATION_EMAIL = "lv@volk.bike"

Write-Host "Starting local test of Health Monitor Function..."
Write-Host "Email notifications enabled: $($env:EMAIL_NOTIFICATIONS_ENABLED)"
Write-Host "Notification email: $($env:NOTIFICATION_EMAIL)"

# Import the function script
. "./src/HealthMonitorFunction/run.ps1"

Write-Host "Test completed!"
