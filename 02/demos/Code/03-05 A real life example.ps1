# A real life example - deploying a data client
# Set Subscription, RG Name etc.
. '.\00 Variables.ps1'

# Set Image Name 
$imageName="aibDataClient"

# Build addl. resource Names 
$identityName="aib"+(Get-Random -Minimum 100000000 -Maximum 99999999999)
$imageRoleDefName="Azure Image Builder Image Def"+(Get-Random -Minimum 100000000 -Maximum 99999999999)
$imageId="/subscriptions/$subscription/resourceGroups/$aibRG/providers/Microsoft.Compute/images/$imageName"

# Set Azure subscription
az account set -s $subscription

# Register providers / check provider state
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages, Microsoft.Network |
  Where-Object RegistrationState -ne Registered |
    Register-AzResourceProvider
# OR you can run Invoke-AIBProviderCheck


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
$TemplateJSON = Get-Content 'ImageTemplate-Data.json.dist' -raw | ConvertFrom-Json
$TemplateJSON.location=$location
$TemplateJSON.identity.userAssignedIdentities = [pscustomobject]@{$imgBuilderId=[pscustomobject]@{}}
$TemplateJSON.properties.distribute[0].runOutputName = $imageName
$TemplateJSON.properties.distribute[0].location = $location
$TemplateJSON.properties.distribute[0].imageId = $imageId
$TemplateJSON | ConvertTo-Json -Depth 4 | Out-File "ImageTemplate-Data.json" -Encoding ascii

# Check out the important settings
$TemplateJSON.properties.vmProfile.vmSize

$TemplateJSON.properties.customize | Select-Object type,name

$TemplateJSON.properties.customize[0].inline
$TemplateJSON.properties.customize[1].inline
$TemplateJSON.properties.customize[1].validExitCodes

# Create template
az image builder create -g $aibRG -n $imageName --image-template ImageTemplate-Data.json

# Build the image
az image builder run -n $imageName -g $aibRG

# Create VM
$VMIP=(az vm create --resource-group $aibRG --name $imageName `
        --admin-username $VM_User --admin-password $WinVM_Password `
        --image $imageId --location $location --public-ip-sku Standard `
        --size $TemplateJSON.properties.vmProfile.vmSize `
        --query publicIpAddress -o tsv)

# Connect to VM
cmdkey /generic:$VMIP /user:$VM_User /pass:$WinVM_Password
mstsc /v:$VMIP /w:1024 /h:768

# Download Logfile from Website
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

# Delete RG
az group delete -g $aibRG --yes