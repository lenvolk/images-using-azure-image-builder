# Author/Build/Deploy PS
# Set Subscription, RG Name etc.
#
# Install-Module Az.ImageBuilder.Tools
# Install-Module -Name Az.ImageBuilder -RequiredVersion 0.1.2
#before proceeding 
# cd 02\demos\Code\ 
. '.\00 Variables.ps1'

# Set Image Name
$imageName="aibImagePSWind"

# Build addl. resource Names 
$identityName="aib"+(Get-Random -Minimum 100000000 -Maximum 99999999999)
$imageRoleDefName="Azure Image Builder Image Def"+(Get-Random -Minimum 100000000 -Maximum 99999999999)
$imageId="/subscriptions/$subscription/resourceGroups/$aibRG/providers/Microsoft.Compute/images/$imageName"

# Login to Azure / set subscription
Connect-AzAccount -Subscription $subscription

# Register providers / check provider state
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages, Microsoft.Network |
  Where-Object RegistrationState -ne Registered |
    Register-AzResourceProvider

# OR you can run Invoke-AIBProviderCheck

# Create resource group
$RGScope=(New-AzResourceGroup -Name $aibRG -Location $location).ResourceId

# Create Identity
$Identity=(New-AzUserAssignedIdentity -ResourceGroupName $aibRG -Name $identityName -Location $location)
$imgBuilderCliId=$Identity.clientId
$imgBuilderId=$Identity.id

# Get role definition, modify, create and assign
$AzureRoleAIB = Get-Content 'AzureRoleAIB.json.dist' -raw | ConvertFrom-Json
$AzureRoleAIB.Name=$imageRoleDefName
$AzureRoleAIB.AssignableScopes[0]=$RGScope
$AzureRoleAIB | ConvertTo-Json | Out-File "AzureRoleAIB.json"

New-AzRoleDefinition -InputFile ./AzureRoleAIB.json

New-AzRoleAssignment -ApplicationId $imgBuilderCliId -RoleDefinitionName $imageRoleDefName -Scope $RGScope

# Define Source
$SrcObjParams = @{
    SourceTypePlatformImage = $true
    Publisher = 'MicrosoftWindowsServer'
    Offer = 'WindowsServer'
    Sku = '2019-Datacenter'
    Version = 'latest'
  }

$srcPlatform = New-AzImageBuilderSourceObject @SrcObjParams

# Define distribution method
# PowerShell requires ArtifactTag!
$distribution =  New-AzImageBuilderDistributorObject -ManagedImageDistributor `
                    -ArtifactTag @{aibgenerated='true'} `
                    -ImageId $imageId -RunOutputName $imageName -Location $location

# define customizers
$ImgCustomParams01 = @{
    PowerShellCustomizer = $true
    CustomizerName = 'HelloFile'
    RunElevated = $false
    Inline = @("mkdir c:\\buildActions", "echo HelloPowerShell  > c:\\buildActions\\helloworld.txt")
}
$Customizer01 = New-AzImageBuilderCustomizerObject @ImgCustomParams01

$Customizer02 = New-AzImageBuilderCustomizerObject -WindowsUpdateCustomizer `
        -Filter ("BrowseOnly", "IsInstalled") -SearchCriterion "BrowseOnly=0 and IsInstalled=0" `
        -UpdateLimit 100 -CustomizerName 'WindUpdate'

# Create template array
$ImgTemplateParams = @{
    ImageTemplateName = $imageName
    ResourceGroupName = $aibRG
    Source = $srcPlatform
    Distribute = $distribution
    Customize = $Customizer01, $Customizer02
    Location = $location
    UserAssignedIdentityId = $imgBuilderId
  }
  
# Create template
New-AzImageBuilderTemplate @ImgTemplateParams

# Build the image
Start-AzImageBuilderTemplate -ResourceGroupName $aibRG -Name $imageName

# Delete the template
$template=Get-AzImageBuilderTemplate -ImageTemplateName $imageName -ResourceGroupName $aibRG
Remove-AzImageBuilderTemplate -InputObject $template

# Delete the identity 
Remove-AzUserAssignedIdentity -ResourceGroupName $aibRG -Name $identityName

# Create VM
New-AzVM -ResourceGroupName $aibRG -Image $imageId -Name $imageName -Credential $Cred

$VMIP=(Get-AzPublicIpAddress -ResourceGroupName $aibRG -Name $imageName).IpAddress

# Connect to VM
cmdkey /generic:$VMIP /user:$VM_User /pass:$WinVM_Password
mstsc /v:$VMIP /w:800 /h:600

# Create additional VM from Image
New-AzVM -ResourceGroupName $aibRG -Image $imageId -Name aibwind2 -Credential $Cred

# Delete RG
Remove-AzResourceGroup -Name $aibRG -Force