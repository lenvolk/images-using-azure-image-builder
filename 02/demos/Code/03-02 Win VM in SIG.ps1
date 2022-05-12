# Creating a SIG- Distribute an Image to a SIG - Run VM From SIG
# Set Subscription, RG Name etc.
. '.\00 Variables.ps1'

# Set Image Name
$PrevImageName="aibImageJSON"
$imageName="aibImageSIG"

# Try to deploy old Image in new Region
az vm create --resource-group $aibRG --name VM_Old `
        --admin-username $VM_User --admin-password $WinVM_Password `
        --image $PrevImageName --location eastus --public-ip-sku Standard 

# Create Shared Image Gallery 
$sigName="aibSig"
az sig create -g $aibRG --gallery-name $sigName

# Create Imagedefinition
$sig_publisher="myPublisher"
$sig_offer="myOffer"
$sig_sku="mySku"

$SigDef=(az sig image-definition create -g $aibRG --gallery-name $sigName `
   --gallery-image-definition $imageName `
   --publisher $sig_publisher --offer $sig_offer --sku $sig_sku `
   --os-type Windows --query id -o tsv)

$SIGLocations=$location,"eastus","westeurope"

$TemplateJSON = Get-Content 'ImageTemplate.json' -raw | ConvertFrom-Json
$dist=$TemplateJSON.properties.distribute[0]
$dist.Type = "SharedImage"
$dist.runOutputName = $imageName
$dist.PSObject.Properties.Remove('imageId')
$dist.PSObject.Properties.Remove('location')
$dist | Add-Member -NotePropertyName galleryImageId -NotePropertyValue $SigDef
$dist | Add-Member -NotePropertyName replicationRegions -NotePropertyValue $SIGLocations
$TemplateJSON.properties.distribute[0]=$dist
$TemplateJSON | ConvertTo-Json -Depth 4 | Out-File "ImageTemplate-SIG.json" -Encoding ascii

code ImageTemplate-SIG.json

# Create template
az image builder create -g $aibRG -n $imageName --image-template ImageTemplate-SIG.json

# Build the image
az image builder run -n $imageName -g $aibRG

# Show image versions
az sig image-version list --gallery-image-definition $imageName `
                          --gallery-name $sigName `
                          --resource-group $aibRG -o table

# Build the image again
az image builder run -n $imageName -g $aibRG

# Show image versions again
az sig image-version list --gallery-image-definition $imageName `
                          --gallery-name $sigName `
                          --resource-group $aibRG -o table

# Create VMs
foreach($loc in $SIGLocations) {
az vm create --resource-group $aibRG --name VM_SIG_$loc `
        --admin-username $VM_User --admin-password $WinVM_Password `
        --image $SigDef/versions/latest --location $loc --public-ip-sku Standard
}

# Check out VMs
az vm list -g $aibRG -o table

# Delete RG
az group delete -g $aibRG --yes