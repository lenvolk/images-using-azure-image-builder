#######################################
#     Create Shared Image Gallery     #
#######################################
#  
$location = "eastus2"
$CompGalNameRG = "AVDCompGalRG"
$CompGalName ="AVDCompGal"
$ImageDefName = "AVDWin11"

az group create -l $location -n $CompGalNameRG

az sig create -g $CompGalNameRG --gallery-name $CompGalName

#######################################
#   Create Imagedefinition            #
#######################################

$publisher="MicrosoftWindowsDesktop"
$offer="windows-11"
$sku="win11-22h2-avd"

$CompGalDef=(az sig image-definition create -g $CompGalNameRG --gallery-name $CompGalName `
   --gallery-image-definition $ImageDefName `
   --publisher $publisher --offer $offer --sku $sku `
   --os-type Windows `
   --hyper-v-generation V2 `
   --query id -o tsv)
