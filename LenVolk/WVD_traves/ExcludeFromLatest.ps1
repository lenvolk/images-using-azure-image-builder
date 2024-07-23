# Log in to Azure with:
Connect-AzAccount

# Verify your logged in with
Get-AzContext

# Set SIG Variables
$resourceGroup = '<SIGResourceGroup>'
$galleryName = '<SIGGalleryName>'
$imageDefName = '<ImageDefinition>'
$imageVersion = '<ImageVersion>'

# Enable Exclude from latest
Update-AzGalleryImageVersion -ResourceGroupName $resourceGroup `
-GalleryName $galleryName `
-GalleryImageDefinitionName $imageDefName `
-Name $imageVersion `
-PublishingProfileExcludeFromLatest 

# View the settings
Get-AzGalleryImageversion -ResourceGroupName $resourceGroup -GalleryName $galleryName `
-GalleryImageDefinitionName $imageDefName -Name $imageVersion


# Disable Exclude from latest
Update-AzGalleryImageVersion -ResourceGroupName $resourceGroup `
-GalleryName $galleryName `
-GalleryImageDefinitionName $imageDefName `
-Name $imageVersion `
-PublishingProfileExcludeFromLatest:$False

# View the settings
Get-AzGalleryImageversion -ResourceGroupName $resourceGroup -GalleryName $galleryName `
-GalleryImageDefinitionName $imageDefName -Name $imageVersion 