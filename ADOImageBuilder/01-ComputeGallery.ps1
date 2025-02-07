$location = "eastus2"
$CompGalNameRG = "CompGalRG"
$CompGalName = "CompGal"
$ImageDefName = "ImDefWin11"

# Create Resource Group
if (-not (Get-AzResourceGroup -Name $CompGalNameRG -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $CompGalNameRG -Location $location
} else {
    Write-Host "Resource Group already exists"
}

# Create Shared Image Gallery
if (-not (Get-AzGallery -ResourceGroupName $CompGalNameRG -GalleryName $CompGalName -ErrorAction SilentlyContinue)) {
    New-AzGallery -ResourceGroupName $CompGalNameRG -GalleryName $CompGalName -Location $location
} else {
    Write-Host "Image Gallery already exists"
}

#######################################
#   Create Image Definition           #
#######################################

$publisher = "MicrosoftWindowsDesktop"
$offer = "windows-11"
$sku = "win11-22h2"

$CompGalDef = New-AzGalleryImageDefinition -ResourceGroupName $CompGalNameRG -GalleryName $CompGalName `
    -Name $ImageDefName -Publisher $publisher -Offer $offer -Sku $sku `
    -OsType Windows `
    -Location $location `
    -OsState generalized 
    #-Feature @{Name='SecurityType';Value='None'}