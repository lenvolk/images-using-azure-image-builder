# Creating a VM Image in an existing VNet
# Set Subscription, RG Name etc.
. '.\00 Variables.ps1'

# Set Image Name
$imageName="aibImageVNET"

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

# Create VNET and Subnet
$VNETName="aibVNet"
$SubnetName="aibSubnet"
az network vnet create --resource-group $aibRG --address-prefixes 10.0.0.0/24 --name $VNETName `
                                            --subnet-prefixes 10.0.0.0/25 --subnet-name $SubnetName 

# Retrieve the ID of that Subnet
$SubnetId=(az network vnet subnet show --resource-group $aibRG --vnet-name $VNETName --name=$SubnetName `
            --query id -o tsv)

# Build VM Profile
# Could also change proxyVmSize from default Standard A1_v2
$vmProfile = [pscustomobject]@{
        osDiskSizeGB=150
        vmSize="Standard_D2_v2"
        vnetConfig=[pscustomobject]@{subnetId=$SubnetId}
}

# Build JSON
$TemplateJSON = Get-Content 'ImageTemplate.json' -raw | ConvertFrom-Json
$TemplateJSON.identity.userAssignedIdentities = [pscustomobject]@{$imgBuilderId=[pscustomobject]@{}}
$TemplateJSON.properties.distribute[0].runOutputName = $imageName
$TemplateJSON.properties.distribute[0].imageId = $imageId
# Add vmProfile
$TemplateJSON.properties | Add-Member -NotePropertyName vmProfile -NotePropertyValue $vmProfile
# To save time, let's reduce the customizations to the first step
$TemplateJSON.properties.customize = @($TemplateJSON.properties.customize[0])
$TemplateJSON | ConvertTo-Json -Depth 4 | Out-File "ImageTemplate-VNET.json" -Encoding ascii

code ImageTemplate-VNET.json

# Create template
az image builder create -g $aibRG -n $imageName --image-template ImageTemplate-VNET.json

# Adjust permissions - if required, add VNet RG or create separate role
$AzureRoleAIB.Actions += "Microsoft.Network/virtualNetworks/read"
# We will also need this - otherwise, we'll get a generic build error
$AzureRoleAIB.Actions += "Microsoft.Network/virtualNetworks/subnets/join/action"
$AzureRoleAIB | ConvertTo-Json | Out-File "AzureRoleAIB.json"
az role definition update --role-definition ./AzureRoleAIB.json

# Try to create template again
az image builder create -g $aibRG -n $imageName --image-template ImageTemplate-VNET.json

# Delete template
az image builder delete -g $aibRG -n $imageName 

# Try to create template again
az image builder create -g $aibRG -n $imageName --image-template ImageTemplate-VNET.json

# Disable Private Link Policy
az network vnet subnet update --name $SubnetName --resource-group $aibRG --vnet-name $VNETName `
                              --disable-private-link-service-network-policies true 

# Delete and re-create template
az image builder delete -g $aibRG -n $imageName 
az image builder create -g $aibRG -n $imageName --image-template ImageTemplate-VNET.json

# Build the image
az image builder run -n $imageName -g $aibRG

# Create VM
az vm create --resource-group $aibRG --name $imageName `
        --admin-username $VM_User --admin-password $WinVM_Password `
        --image $imageId --location $location --public-ip-sku Standard 

# Get disk size
az vm show --resource-group $aibRG --name $imageName --query storageProfile.osDisk.diskSizeGb