# Creating a VM Image in an existing VNet
# Set Subscription, RG Name etc.
. '.\00 Variables.ps1'

# Set Image Name
$imageName="ChocoWin11"

# Build addl. resource Names 
$identityName="aib"+(Get-Random -Minimum 100000000 -Maximum 99999999999)
$imageRoleDefName="Azure Image Builder Image Def"+(Get-Random -Minimum 100000000 -Maximum 99999999999)
# Existing Role
# $imageRoleDefName="Azure Image Builder Image Def1236734744"

# Set Azure subscription
az account set -s $subscription

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

# Adjust permissions - if required, add VNet RG or create separate role
$AzureRoleAIB.Actions += "Microsoft.Network/virtualNetworks/read"
# We will also need this - otherwise, we'll get a generic build error
$AzureRoleAIB.Actions += "Microsoft.Network/virtualNetworks/subnets/join/action"
$AzureRoleAIB | ConvertTo-Json | Out-File "AzureRoleAIB.json"

az role definition create --role-definition ./AzureRoleAIB.json
# az role definition update --role-definition ./AzureRoleAIB.json

az role assignment create --assignee $imgBuilderCliId --role $imageRoleDefName --scope $RGScope

# Create VNET and Subnet
$VNETName="aibVNet"
$SubnetName="aibSubnet"
az network vnet create --resource-group $aibRG --address-prefixes 10.150.0.0/24 --name $VNETName `
                                            --subnet-prefixes 10.150.0.0/25 --subnet-name $SubnetName 
# Disable Private Link Policy
az network vnet subnet update --name $SubnetName --resource-group $aibRG --vnet-name $VNETName `
                              --disable-private-link-service-network-policies true 
# Retrieve the ID of that Subnet
$SubnetId=(az network vnet subnet show --resource-group $aibRG --vnet-name $VNETName --name=$SubnetName `
            --query id -o tsv)

# Build VM Profile
# Could also change proxyVmSize from default Standard A1_v2
$vmProfile = [pscustomobject]@{
        osDiskSizeGB=150
        vmSize="Standard_D4s_v3"
        vnetConfig=[pscustomobject]@{subnetId=$SubnetId}
}

# Get Existing Shared Image Gallery 
$sigName="aibSig"
# az sig create -g $aibRG --gallery-name $sigName

# Create Imagedefinition
$sig_publisher="myPublisher3"
$sig_offer="myOffer3"
$sig_sku="mySku3"

$SigDef=(az sig image-definition create -g $aibRG --gallery-name $sigName `
   --gallery-image-definition $imageName `
   --publisher $sig_publisher --offer $sig_offer --sku $sig_sku `
   --os-type Windows `
   --hyper-v-generation V2 `
   --query id -o tsv)

$SIGLocations=$location,"eastus","westeurope"

# Build JSON

$TemplateJSON = Get-Content 'ImageTemplate.json.dist' -raw | ConvertFrom-Json
$TemplateJSON.location=$location
$dist=$TemplateJSON.properties.distribute[0]
$dist.Type = "SharedImage"
$dist.runOutputName = $imageName
$dist.PSObject.Properties.Remove('imageId')
$dist.PSObject.Properties.Remove('location')
$dist | Add-Member -NotePropertyName galleryImageId -NotePropertyValue $SigDef
$dist | Add-Member -NotePropertyName replicationRegions -NotePropertyValue $SIGLocations
$TemplateJSON.identity.userAssignedIdentities = [pscustomobject]@{$imgBuilderId=[pscustomobject]@{}}
$TemplateJSON.properties.distribute[0]=$dist
# Add vmProfile
$TemplateJSON.properties | Add-Member -NotePropertyName vmProfile -NotePropertyValue $vmProfile
# If you want to save time only customizations to the first step
# $TemplateJSON.properties.customize = @($TemplateJSON.properties.customize[0])
$TemplateJSON | ConvertTo-Json -Depth 4 | Out-File "AIB-ChocoWin11.json" -Encoding ascii

code AIB-Choco.json

$TemplateJSON.properties.vmProfile.vmSize

$TemplateJSON.properties.customize | Select-Object type,name

$TemplateJSON.properties.customize[0].inline
$TemplateJSON.properties.customize[1].inline
$TemplateJSON.properties.customize[1].validExitCodes


# Delete and re-create template
# az image builder delete -g $aibRG -n $imageName 
az image builder create -g $aibRG -n $imageName --image-template AIB-ChocoWin11.json

# Build the image
az image builder run -n $imageName -g $aibRG


# Create VM
$VMIP=( az vm create --resource-group $aibRG --name $imageName `
                    --admin-username $VM_User --admin-password $WinVM_Password `
                    --image $SigDef/versions/latest --location $location --public-ip-sku Standard `
                    --tags 'demo=LenVolk' `
                    --query publicIpAddress -o tsv)

# Get disk size
az vm show --resource-group $aibRG --name $imageName --query storageProfile.osDisk.diskSizeGb

# Connect to VM
cmdkey /generic:$VMIP /user:$VM_User /pass:$WinVM_Password
mstsc /v:$VMIP /w:1024 /h:768

# Download Logfile from AIB SA
# Point to logfile
$Logfile="C:\Users\PSDemo\Downloads\Customization.Log"

# Check out logfile
code $Logfile

# It's pretty big...
grep "PACKER OUT" $Logfile | grep : > Log_Clean.log

# Check out again
code Log_Clean.log

# Clean up a bit more
get-content Log_Clean.log | foreach {
   $items = $_.split(":")
   echo $_.replace($items[0],'')
} > Log_Clean_2.log

# Check out again
code Log_Clean_2.log



# Delete VMs
$VMs=(az vm list -g $aibRG | ConvertFrom-Json)
foreach($VM in $VMs) {
    az vm delete -n $VM.name -g $aibRG --yes
}
 
# Delete other resources
$Resources=(az resource list --tag 'demo=LenVolk' | ConvertFrom-Json)
foreach($res in $Resources) {
    az resource delete -n $res.name -g $aibRG --resource-type $res.type
}