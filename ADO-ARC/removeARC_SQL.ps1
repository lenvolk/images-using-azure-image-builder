# Login to Azure
# Connect-AzAccount

# Define the tag to filter by
$tagName = "YourTagName"
$tagValue = "YourTagValue"

# Get all resources of the specified type and filter by tag
$resources = Get-AzResource -ResourceType "Microsoft.AzureArcData/SqlServerInstances" | Where-Object { $_.Tags[$tagName] -eq $tagValue }

# Export resources to CSV file
$csvFilePath = "C:\path\to\your\resources.csv"
$resources | Select-Object ResourceId, ResourceName, ResourceType, Location, Tags | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Output "Resources have been exported to $csvFilePath."

# Import resources from CSV file and remove them
$importedResources = Import-Csv -Path $csvFilePath

foreach ($resource in $importedResources) {
    Remove-AzResource -ResourceId $resource.ResourceId -Force
}

Write-Output "All resources listed in the CSV file have been removed."