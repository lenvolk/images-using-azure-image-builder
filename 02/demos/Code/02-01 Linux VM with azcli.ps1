# Author/Build/Deploy CLI
# Upgrade az data 
choco upgrade azure-cli
az upgrade

# Set Subscription, RG Name etc.
# cd .\02\demos\Code\
# code '00 Variables.ps1'
. '.\00 Variables.ps1'

# Set Image Name and Source
$imageName = "aibImageAzLinux"
$imageSource = "Canonical:UbuntuServer:18.04-LTS:Latest"

# Build addl. resource Names 
$identityName = "aib" + (Get-Random -Minimum 100000000 -Maximum 99999999999)
$imageRoleDefName = "Azure Image Builder Image Def" + (Get-Random -Minimum 100000000 -Maximum 99999999999)
$imageId = "/subscriptions/$subscription/resourceGroups/$aibRG/providers/Microsoft.Compute/images/$imageName"

# Login to Azure / set subscription
az login --only-show-errors -o table --query Dummy
az account set -s $subscription

# Register providers / check provider state
az provider register -n Microsoft.VirtualMachineImages
az provider register -n Microsoft.Compute
az provider register -n Microsoft.KeyVault
az provider register -n Microsoft.Storage
az provider register -n Microsoft.Network

# would need to be run from start/run/wsl
az provider show -n Microsoft.VirtualMachineImages | grep registrationState
az provider show -n Microsoft.KeyVault | grep registrationState
az provider show -n Microsoft.Compute | grep registrationState
az provider show -n Microsoft.Storage | grep registrationState
az provider show -n Microsoft.Network | grep registrationState

# Create resource group
$RGScope = (az group create -n $aibRG -l $location --query id -o tsv)

# Create Identity
$Identity = (az identity create -g $aibRG -n $identityName) | ConvertFrom-Json
$imgBuilderCliId = $Identity.clientId
$imgBuilderId = $Identity.id

# Get role definition, modify, create and assign
code AzureRoleAIB.json.dist
$AzureRoleAIB = Get-Content 'AzureRoleAIB.json.dist' -raw | ConvertFrom-Json
$AzureRoleAIB.Name = $imageRoleDefName
$AzureRoleAIB.AssignableScopes[0] = $RGScope
$AzureRoleAIB | ConvertTo-Json | Out-File "AzureRoleAIB.json"
code -d AzureRoleAIB.json.dist AzureRoleAIB.json

az role definition create --role-definition ./AzureRoleAIB.json

az role assignment create --assignee $imgBuilderCliId --role $imageRoleDefName --scope $RGScope

# Create template
az image builder create --name $imageName -g $aibRG --identity $identityName `
    --image-source $imageSource --managed-image-destinations "$imageName=$location" --defer

# Create Customizers
az image builder customizer add -n $imageName -g $aibRG `
    --inline-script "sudo mkdir /buildArtifacts" `
    "sudo echo hello > /buildArtifacts/helloworld" `
    --customizer-name HelloFile --type shell  --defer

az image builder customizer add -n $imageName -g $aibRG `
    --inline-script "sudo apt install unattended-upgrades" `
    --customizer-name Upgrades --type shell --defer

# Check current cache
az cache list -o table

# Check template in Azure
az image builder show -n $imageName -g $aibRG -o table

# Apply changes
az image builder update -n $imageName -g $aibRG

# Check cache and Azure again
az cache list -o table
az image builder show -n $imageName -g $aibRG -o table

# Build the image
az image builder run -n $imageName -g $aibRG

# Delete the template
az image builder delete -n $imageName -g $aibRG

# Delete the identity 
az identity delete -g $aibRG -n $identityName

# Create VM
$VMIP = (az vm create --resource-group $aibRG --name $imageName `
        --generate-ssh-keys --admin-username $VM_User `
        --image $imageId --location $location --public-ip-sku Standard `
        --query publicIpAddress -o tsv)

# Connect to VM
ssh $VM_User@$VMIP
# cat /buildArtifacts/helloworld
# exit

# Delete RG
az group delete -g $aibRG --yes
