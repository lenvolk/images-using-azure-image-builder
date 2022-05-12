# Author/Create JSON - JSON to ARM - Create from ARM
# Set Subscription, RG Name etc.
. '.\00 Variables.ps1'

# Set Image Name
$imageName="aibImageJSON"

# Build addl. resource Names 
$identityName="aib"+(Get-Random -Minimum 100000000 -Maximum 99999999999)
$imageRoleDefName="Azure Image Builder Image Def"+(Get-Random -Minimum 100000000 -Maximum 99999999999)
$imageId="/subscriptions/$subscription/resourceGroups/$aibRG/providers/Microsoft.Compute/images/$imageName"

# Set Azure subscription
az account set -s $subscription

# Create resource group
$RGScope=(az group create -n $aibRG -l $location --query id -o tsv)

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

# Build JSON
code ImageTemplate.json.dist

(curl https://bookmark.ws/AIB_SampleScript).Content
(curl https://bookmark.ws/AIB_SampleFile).Content

$TemplateJSON = Get-Content 'ImageTemplate.json.dist' -raw | ConvertFrom-Json
$TemplateJSON.location=$location
$TemplateJSON.identity.userAssignedIdentities = [pscustomobject]@{$imgBuilderId=[pscustomobject]@{}}
$TemplateJSON.properties.distribute[0].runOutputName = $imageName
$TemplateJSON.properties.distribute[0].location = $location
$TemplateJSON.properties.distribute[0].imageId = $imageId
$TemplateJSON | ConvertTo-Json -Depth 4 | Out-File "ImageTemplate.json" -Encoding ascii

code -d ImageTemplate.json.dist ImageTemplate.json

# Create template
az image builder create -g $aibRG -n $imageName --image-template ImageTemplate.json

# Check template in Azure
az image builder show -n $imageName -g $aibRG -o table

# Turn into ARM
code ImageTemplate-ARM.json.dist

$ARM = Get-Content 'ImageTemplate-ARM.json.dist' -raw | ConvertFrom-Json
$TemplateJSON = Get-Content 'ImageTemplate.json' -raw | ConvertFrom-Json
$TemplateJSON | Add-Member -NotePropertyName Name -NotePropertyValue 'aibImageARM'
$ARM.resources[0]=$TemplateJSON
$ARM | ConvertTo-Json -Depth 6 | Out-File "ImageBuilder-ARM.json"

code ImageBuilder-ARM.json

# Create template from ARM
az deployment group create --resource-group $aibRG --template-file ImageBuilder-ARM.json

# Show templates
az image builder list -g $aibRG -o table

# Delete ARM based template
az image builder delete -g $aibRG -n aibImageARM