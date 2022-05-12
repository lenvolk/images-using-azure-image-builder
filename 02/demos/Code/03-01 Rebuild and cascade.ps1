# Rebuild Images - Cascade Images
# Set Subscription, RG Name etc.
. '.\00 Variables.ps1'

# Set Image Name
$imageName="aibImageJSON"

# Build the Image
az image builder run -n $imageName -g $aibRG

# Create a VM
$VMIP_1=(az vm create --resource-group $aibRG --name VM1 `
        --admin-username $VM_User --admin-password $WinVM_Password `
        --image $imageId --location $location --public-ip-sku Standard `
        --tags 'demo=0301' `
        --query publicIpAddress -o tsv)

# Build the Image again
az image builder run -n $imageName -g $aibRG

# List the image(s)
az resource list -g $aibRG -o table --resource-type Microsoft.Compute/images

# Create two more VMs
$VMIP_2=(az vm create --resource-group $aibRG --name VM2 `
        --admin-username $VM_User --admin-password $WinVM_Password `
        --image $imageId --location $location --public-ip-sku Standard `
        --tags 'demo=0301' `
        --query publicIpAddress -o tsv)

$VMIP_3=(az vm create --resource-group $aibRG --name VM3 `
        --admin-username $VM_User --admin-password $WinVM_Password `
        --image $imageId --location $location --public-ip-sku Standard `
        --tags 'demo=0301' `
        --query publicIpAddress -o tsv)

# Connect to VMs
cmdkey /generic:$VMIP_1 /user:$VM_User /pass:$WinVM_Password
cmdkey /generic:$VMIP_2 /user:$VM_User /pass:$WinVM_Password
cmdkey /generic:$VMIP_3 /user:$VM_User /pass:$WinVM_Password
mstsc /v:$VMIP_1 /w:800 /h:400
mstsc /v:$VMIP_2 /w:800 /h:400
mstsc /v:$VMIP_3 /w:800 /h:400

# Cascading Images
# Set new Image Name and Id
$imageName="aibImageCascaded"
$imageSource=$imageId
$imageId="/subscriptions/$subscription/resourceGroups/$aibRG/providers/Microsoft.Compute/images/$imageName"

# Retrieve existing Identity
$Identities=(az identity list -g $aibRG) | ConvertFrom-Json
$Identity=(az identity show -g $aibRG -n $Identities[0].name) | ConvertFrom-Json
$imgBuilderCliId=$Identity.clientId
$imgBuilderId=$Identity.id

# Create template
az image builder create --name $imageName -g $aibRG --identity $identityName `
    --image-source $imageSource --managed-image-destinations $imageName=$location --defer

# Add Customizer
az image builder customizer add -n $imageName -g $aibRG `
    --inline-script "echo hello > C:\\ImageBuilder\\Cascade.txt" `
    --customizer-name HelloFile --type PowerShell  --defer

# Create template
az image builder update -n $imageName -g $aibRG

# Build the image
az image builder run -n $imageName -g $aibRG

# Create VM
$VMIP=(az vm create --resource-group $aibRG --name VMCascade `
        --admin-username $VM_User --admin-password $WinVM_Password `
        --image $imageId --location $location --public-ip-sku Standard `
        --tags 'demo=0301' `
        --query publicIpAddress -o tsv)

# Connect to VM
cmdkey /generic:$VMIP /user:$VM_User /pass:$WinVM_Password
mstsc /v:$VMIP /w:800 /h:600


# Delete VMs
$VMs=(az vm list -g $aibRG | ConvertFrom-Json)
foreach($VM in $VMs) {
    az vm delete -n $VM.name -g $aibRG --yes
}
 
# Delete other resources
$Resources=(az resource list --tag 'demo=0301' | ConvertFrom-Json)
foreach($res in $Resources) {
    az resource delete -n $res.name -g $aibRG --resource-type $res.type
}