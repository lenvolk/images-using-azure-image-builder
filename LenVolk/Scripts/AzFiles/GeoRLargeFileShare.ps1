# Ref https://learn.microsoft.com/en-us/azure/storage/files/geo-redundant-storage-for-large-file-shares?tabs=powershell#register-for-the-feature


Connect-AzAccount -SubscriptionId f043b87b-e870-4884-b2d1-d665cc58f247 -TenantId 55c5efb8-a532-4676-b1c3-64406cee8104
Register-AzProviderFeature -FeatureName AllowLfsForGRS -ProviderNamespace Microsoft.Storage

Get-AzProviderFeature -FeatureName "AllowLfsForGRS" -ProviderNamespace "Microsoft.Storage"