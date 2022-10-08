# Creating a SIG- Distribute an Image to a SIG - Run VM From SIG
# Set Subscription, RG Name etc.
. '.\00 Variables.ps1'

az login --only-show-errors -o table --query Dummy
# Set Azure subscription
az account set -s $subscription

# Set Image Name
$PrevImageName="aibImageJSON"
$imageName="aibImageSIG"


# Build addl. resource Names 
$identityName="aib"+(Get-Random -Minimum 100000000 -Maximum 99999999999)
$imageRoleDefName="Azure Image Builder Image Def"+(Get-Random -Minimum 100000000 -Maximum 99999999999)

# Create resource group
$RGScope=(az group create -n $aibRG -l $location --query id -o tsv)

# Get existing Identity
# $identityName=((az identity list -g $aibRG) | ConvertFrom-Json).name
# $Identity=(az identity show -n $identityName -g $aibRG) | ConvertFrom-Json
# $imgBuilderCliId=$Identity.clientId
# $imgBuilderId=$Identity.id

# Create Identity
$Identity=(az identity create -g $aibRG -n $identityName) | ConvertFrom-Json
$imgBuilderCliId=$Identity.clientId
$imgBuilderId=$Identity.id

# Get role definition, modify, create and assign
$AzureRoleAIB = Get-Content 'AzureRoleAIB.json.dist' -raw | ConvertFrom-Json
$AzureRoleAIB.Name=$imageRoleDefName
$AzureRoleAIB.AssignableScopes[0]=$RGScope
$AzureRoleAIB | ConvertTo-Json | Out-File "AzureRoleAIB.json"
az role definition create --role-definition ./AzureRoleAIB.json

az role assignment create --assignee $imgBuilderCliId --role $imageRoleDefName --scope $RGScope

# Try to deploy old Image in new Region. Will fail
# az vm create --resource-group $aibRG --name VM_Old `
#         --admin-username $VM_User --admin-password $WinVM_Password `
#         --image $PrevImageName --location eastus --public-ip-sku Standard 

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
$TemplateJSON.identity.userAssignedIdentities = [pscustomobject]@{$imgBuilderId=[pscustomobject]@{}}
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

# Show image versions again, it increased 
az sig image-version list --gallery-image-definition $imageName `
                          --gallery-name $sigName `
                          --resource-group $aibRG -o table

# Create VMs

foreach($loc in $SIGLocations) {
az vm create --resource-group $aibRG --name VM_SIG_$loc `
        --admin-username $VM_User --admin-password $WinVM_Password `
        --image $SigDef/versions/latest --location $loc --public-ip-sku Standard `
        --tags 'demo=0302' `
        --query publicIpAddress -o tsv } 


# Check out VMs
az vm list -g $aibRG -o table

# Delete VMs
$VMs=(az vm list -g $aibRG | ConvertFrom-Json)
foreach($VM in $VMs) {
    az vm delete -n $VM.name -g $aibRG --yes
}
 
# Delete other resources
$Resources=(az resource list --tag 'demo=0302' | ConvertFrom-Json)
foreach($res in $Resources) {
    az resource delete -n $res.name -g $aibRG --resource-type $res.type
}

# Delete RG
az group delete -g $aibRG --yes