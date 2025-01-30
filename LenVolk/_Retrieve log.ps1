# Retrieving the customization logfile
# Set Subscription, RG Name etc.
. '.\00 Variables.ps1'

# Set Image Name
$imageName="ChocoWin11O365"

# Check last status
az image builder show --name $imageName --resource-group $aibRG --query lastRunStatus -o table

# Get name of temp RG
$ITRG=(az group list --query "[?tags.createdBy=='AzureVMImageBuilder' && tags.imageTemplateName=='$imageName' && tags.imageTemplateResourceGroupName == '$aibRG'].{Name:name}" -o tsv)

# Find storage account 
# All of this will only work if you haven't manually modified the temp RG!
$StorageAcct=(az storage account list -g $ITRG -o tsv --query '[0].[id]')

# Get connection string
$BlobConnStr=(az storage account show-connection-string  --ids $StorageAcct -o tsv)

# Get list of files
$filelist=(az storage fs file list -f packerlogs --connection-string $BlobConnStr -o json) | ConvertFrom-Json 

# There is one file
# If there were multiple builds, each build would have resulted in a file!
$filelist | Select-Object name

# get latest logfile
$logfile=($filelist | Sort-Object -Property Lastmodified `
         | Select-Object -Last 1 -Property Name -ExpandProperty Name)

# Download logfile
az storage fs file download -f packerlogs -p $logfile --overwrite true --connection-string $BlobConnStr

# Check out logfile
grep completed customization.log | grep OUT

# Delete logfile
remove-item customization.log

# Delete RG
az group delete -g $aibRG --yes