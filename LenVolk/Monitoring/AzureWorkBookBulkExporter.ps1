######################################################################################
#  Name:     AzureWorkbookBulkExporter.ps1
#  Author:   Rogerio Barros
#  Date:     08-01-2024
#  Version   1.0
#  Comment:  This script allows to export all workbooks from an Azure Subscription and save them 
#            and save organized in folders automatically with the resource group name on it
#
######################################################################################


# You will have to change this on the script:
Connect-AzAccount -Tenant 1111-2222-333 # Replace by your tenant ID

# Base folder where the exported files will be sent to 
$baseoutputpath = "c:\temp\ContosoWorkbooksBackup"

########################

write-host "Please select a subscription on the window that will pop up" -ForegroundColor Green
$selectedSubscription = Get-AzSubscription | Out-GridView -PassThru -Title "Choose one subscription (only one, don't multi-select) an click ok"

write-host "Setting context to the selected subscription"
Set-AzContext -SubscriptionObject $selectedSubscription

function GetWorkbookContent # Gets workbook content from REST API
{
    Param([string]$WBResourceID)
    $APICallPath = $WBResourceID + "?api-version=2022-04-01&canFetchContent=true"
    $wbobject = invoke-AzRestMethod -path $APICallPath
    $WBContent = ($wbobject.content | convertfrom-json)
    return $WBContent
}

# List all the workbooks on the subscription
$workbookslist = Get-AzResource -resourcetype microsoft.Insights/workbooks

foreach ($workbook in $workbookslist)
{
    $workbookContent = GetWorkbookContent -WBResourceID $workbook.ResourceId
    $workbookName = $WorkbookContent.Properties.displayName
    $workbookCode = $WorkbookContent.properties.serializedData
    write-host "Processing workbook " $workbookName -ForegroundColor Yellow
    #prepare output to file - create subfolders for each resource group
    $outputpath = join-path $baseoutputpath $workbook.ResourceGroupName
    if (!(test-path $outputpath))
    {
        mkdir $outputpath -Force
    }
    $filename = $workbookName + ".workbook"
    $filename = $filename.replace(":","_")
    $outputfile = Join-Path $outputpath $filename
    $WorkbookCode | Out-File $outputfile -Force
}

