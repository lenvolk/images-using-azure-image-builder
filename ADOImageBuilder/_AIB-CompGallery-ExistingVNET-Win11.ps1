# Install-Module Microsoft.Graph.Authentication
# Install-Module Microsoft.Graph.Applications
# az login --only-show-errors -o table --query Dummy
# az account set -s "AVD"

# az login --scope https://management.core.windows.net//.default

$aibRG = "AIB01RG"
$location = "eastus2"


#######################################
#              Set Names              #
#######################################

$imageName="ChocoWin11m365"

#######################################
#         Create resource group       #
#######################################
$RGScope=(az group create -n $aibRG -l $location --query id -o tsv)

# #######################################
# #         Create Identity             #
# #######################################

# $Identity=(az identity create -g $aibRG -n $identityName) | ConvertFrom-Json
# $imgBuilderCliId=$Identity.clientId
# $imgBuilderId=$Identity.id

# #######################################
# # Get role definition, modify assign  #
# #######################################
# # 
# $AzureRoleAIB = Get-Content 'AzureRoleAIB.json.dist' -raw | ConvertFrom-Json
# $AzureRoleAIB.Name=$imageRoleDefName
# $AzureRoleAIB.AssignableScopes[0]=$RGScope
# $AzureRoleAIB | ConvertTo-Json | Out-File "AzureRoleAIB.json"
# az role definition create --role-definition ./AzureRoleAIB.json
# # az role definition delete --name $imageRoleDefName

# # Adjust permissions - if required, add VNet RG or create separate role
# $AzureRoleAIB.Actions += "Microsoft.Network/virtualNetworks/read"
# # We will also need this - otherwise, we'll get a generic build error
# $AzureRoleAIB.Actions += "Microsoft.Network/virtualNetworks/subnets/join/action"
# $AzureRoleAIB | ConvertTo-Json | Out-File "AzureRoleAIB.json"
# az role definition update --role-definition ./AzureRoleAIB.json

# az role assignment create --assignee $imgBuilderCliId --role $imageRoleDefName --scope $RGScope
$imgBuilderId = "/subscriptions/cb38ca72-3c1a-49c3-aeff-7a659db7110c/resourcegroups/Identities/providers/Microsoft.ManagedIdentity/userAssignedIdentities/AIBMSI"

# #######################################
# #     Create VNET and Subnet          #
# #######################################
$VNETName="aibVNet"
$SubnetName="aibSubnet"
az network vnet create --resource-group $aibRG --address-prefixes 10.150.0.0/24 --name $VNETName `
                                               --subnet-prefixes 10.150.0.0/25 --subnet-name $SubnetName 
# Disable Private Link Policy
az network vnet subnet update --name $SubnetName --resource-group $aibRG --vnet-name $VNETName `
                                                 --private-link-service-network-policies Disabled
# Retrieve the ID of that Subnet
$SubnetId=(az network vnet subnet show --resource-group $aibRG --vnet-name $VNETName --name=$SubnetName --query id -o tsv)

#######################################
#     Create Shared Image Gallery     #
#######################################
#  
$sigName="aibSig01"
az sig create -g $aibRG --gallery-name $sigName

#######################################
#   Create Imagedefinition            #
#######################################

$sig_publisher="myPublisher"
$sig_offer="myOffer"
$sig_sku="mySku"

$SigDef=(az sig image-definition create -g $aibRG --gallery-name $sigName `
   --gallery-image-definition $imageName `
   --publisher $sig_publisher --offer $sig_offer --sku $sig_sku `
   --os-type Windows `
   --hyper-v-generation V2 `
   --query id -o tsv)

$SIGLocations=$location #,"eastus","westeurope"

#######################################
#     Build VM Profile                #
#######################################
$vmProfile = [pscustomobject]@{
    osDiskSizeGB=150
    vmSize="Standard_D8s_v3"
    vnetConfig=[pscustomobject]@{subnetId=$SubnetId}
}

#######################################
#              Build JSON             #
#######################################

#Ref of the template https://learn.microsoft.com/en-us/azure/templates/microsoft.virtualmachineimages/2020-02-14/imagetemplates?pivots=deployment-language-bicep
# Get-AzVMImageSku -Location eastus2 -PublisherName MicrosoftWindowsDesktop -Offer office-365 | select Skus | Where-Object { $_.Skus -like 'win11*'}
# Get-AzVmImageSku -Location eastus2 -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-11'| Select Skus
# az vm image list --publisher MicrosoftWindowsDesktop --sku g2 --output table --all



$TemplateJSON = Get-Content 'ImageTemplate.json.dist' -raw | ConvertFrom-Json
$TemplateJSON.location=$location
$TemplateJSON.tags.ImagebuilderTemplate="ChocoWin11"
$TemplateJSON.properties.source.publisher = "microsoftwindowsdesktop"
$TemplateJSON.properties.source.offer = "office-365"
$TemplateJSON.properties.source.sku = "win11-24h2-avd-m365"
$dist=$TemplateJSON.properties.distribute[0]
$dist.Type = "SharedImage"
$dist.runOutputName = $imageName
$dist.PSObject.Properties.Remove('imageId')
$dist.PSObject.Properties.Remove('location')
$dist | Add-Member -NotePropertyName galleryImageId -NotePropertyValue $SigDef
# $dist | Add-Member -NotePropertyName replicationRegions -NotePropertyValue $SIGLocations
$dist | Add-Member -NotePropertyName replicationRegions -NotePropertyValue @($SIGLocations)
$dist.artifactTags.baseosimg = "windows11m365"
$TemplateJSON.identity.userAssignedIdentities = [pscustomobject]@{$imgBuilderId=[pscustomobject]@{}}
$TemplateJSON.properties.distribute[0]=$dist
# Add vmProfile
$TemplateJSON.properties | Add-Member -NotePropertyName vmProfile -NotePropertyValue $vmProfile
# If you want to save time only customizations to the first step
# $TemplateJSON.properties.customize = @($TemplateJSON.properties.customize[0])
$TemplateJSON | ConvertTo-Json -Depth 4 | Out-File "AIB-ChocoWin11.json" -Encoding ascii


#######################################
#    Delete and re-create template    #
#######################################

# az image builder delete -g $aibRG -n $imageName 
az image builder create -g $aibRG -n $imageName --image-template AIB-ChocoWin11.json

# Build the image
az image builder run -n $imageName -g $aibRG

# # Check last status
# az image builder show --name $imageName --resource-group $aibRG --query lastRunStatus -o table

# # Verify the image version  $SigDef/versions/latest
# $ImageID = (AzGalleryImageversion -ResourceGroupName $aibRG -GalleryName $sigName `
# -GalleryImageDefinitionName $imageName).id | Sort-Object -bottom 1

#######################################
#         Test VMs creation           #
#######################################
# $aibRG = "AIB01RG"
# $location = "eastus2"
# $sigName="aibSig01"
# $imageName="ChocoWin11m365"
# $ImageID = (Get-AzGalleryImageVersion -ResourceGroupName $aibRG -GalleryName $sigName `
# -GalleryImageDefinitionName $imageName).id | Sort-Object -bottom 1

# #will be using existing vnet which is peered to our network
# $vnetResourceGroup = "AVDNetWork"
# $vnetName = "AVDVNet"
# $subnetName = "PooledHP"
# $SubnetID = az network vnet subnet show -g $vnetResourceGroup -n $subnetName  --vnet-name $vnetName --query id --output tsv

# $VM_User = "aibadmin"
# $WinVM_Password = "P@ssw0rdP@ssw0rd"
# $securePassword = ConvertTo-SecureString $WinVM_Password -AsPlainText -Force
# $cred = New-Object System.Management.Automation.PSCredential ($VM_User, $securePassword)

# az vm create --resource-group $aibRG --name $imageName `
#              --admin-username $VM_User --admin-password $WinVM_Password `
#              --image $ImageID --location $location `
#              --public-ip-address " " --nsg " " --subnet $SubnetID `
#              --size 'Standard_B2ms' --tags 'demo=LenVolk'

             
# To test VM creation by regions
# foreach($loc in $SIGLocations) {
#         az vm create --resource-group $aibRG --name $imageName `
#                     --admin-username $VM_User --admin-password $WinVM_Password `
#                     --image $ImageID --location $location --public-ip-sku Standard `
#                     --size 'Standard_B2ms' --tags 'demo=LenVolk' `
#                     --query publicIpAddress -o tsv } 

# # Check out VMs
# az vm list -g $aibRG -o table

# # Get disk size
# az vm show --resource-group $aibRG --name $imageName --query storageProfile.osDisk.diskSizeGb

# # Connect to VM $VMIP= "20.7.0.224"
# cmdkey /generic:$VMIP /user:$VM_User /pass:$WinVM_Password
# mstsc /v:$VMIP /w:1440 /h:900

#######################################
#            AIB Logs                 #
#######################################

# # Download Logfile from AIB SA
# # Point to logfile
# $Logfile="C:\Users\PSDemo\Downloads\Customization.Log"

# # Check out logfile
# code $Logfile

# # It's pretty big...
# grep "PACKER OUT" $Logfile | grep : > Log_Clean.log

# # Check out again
# code Log_Clean.log

# # Clean up a bit more
# get-content Log_Clean.log | foreach {
#    $items = $_.split(":")
#    echo $_.replace($items[0],'')
# } > Log_Clean_2.log

# # Check out again
# code Log_Clean_2.log


#######################################
#         Clean UP                    #
#######################################
# # Delete VMs
# $VMs=(az vm list -g $aibRG | ConvertFrom-Json)
# foreach($VM in $VMs) {
#     az vm delete -n $VM.name -g $aibRG --yes
# }
 
# # Delete other resources
# $Resources=(az resource list --tag 'demo=LenVolk' | ConvertFrom-Json)
# foreach($res in $Resources) {
#     az resource delete -n $res.name -g $aibRG --resource-type $res.type
# }

# az group delete -g $aibRG --yes --no-wait
# az role definition delete --name $imageRoleDefName
