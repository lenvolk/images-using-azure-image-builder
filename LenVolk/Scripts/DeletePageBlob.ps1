
# Ref https://supportability.visualstudio.com/AzureDev/_wiki/wikis/AzureDev/662529/Delete-PageBlob-PowerShell-Script
# Function https://techcommunity.microsoft.com/t5/azure-paas-blog/lifecycle-management-for-page-blob-and-block-blob-using-function/ba-p/2801787

param(
    [parameter(Mandatory=$true)]
    [String]$resourceGroupName,

    # StorageAccount name for content deletion.
    [Parameter(Mandatory = $true)] 
    [String]$StorageAccountName,

    # StorageContainer name for content deletion.
    [Parameter(Mandatory = $true)] 
    [String]$ContainerName,

    [Parameter(Mandatory = $true)]
    [Int32]$DaysOld

)
$keys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $StorageAccountName
# get the storage account key
# get the context
$StorageAccountContext = New-AzStorageContext -storageAccountName $StorageAccountName -StorageAccountKey $keys.Value[0];
$existingContainer = Get-AzStorageContainer -Context $StorageAccountContext -Name $ContainerName;
if (!$existingContainer)
{
"Could not find storage container";
} 
else 
{
$containerName = $existingContainer.Name;
$blobs = Get-AzStorageBlob -Container $containerName -Context $StorageAccountContext;

$blobs = $blobs 
$blobsremoved = 0;


if ($blobs -ne $null)
{    
    foreach ($blob in $blobs)
    {
        $lastModified = $blob.LastModified
        if ($lastModified -ne $null)
        {
            #Write-Verbose ("Now is: {0} and LastModified is:{1}" –f [DateTime]::Now, [DateTime]$lastModified);
            #Write-Verbose ("lastModified: {0}" –f $lastModified);
            #Write-Verbose ("Now: {0}" –f [DateTime]::Now);
            $blobDays = ([DateTime]::Now - $lastModified.DateTime)  #[DateTime]

            Write-output ("Blob {0} has been in storage for {1} days" –f $blob.Name, $blobDays);

            Write-output ("blobDays.Days: {0}" –f $blobDays.Hours);
            Write-output ("DaysOld: {0}" –f $DaysOld);

            if ($blobDays.Days -le $DaysOld)
            {
                Write-output ("Removing Blob: {0}" –f $blob.Name);

                Remove-AzStorageBlob -Blob $blob.Name -Container $containerName -Context $StorageAccountContext;
                $blobsremoved += 1;
            }
            else {
                Write-output ("Not removing blob as it is not old enough.");
            }
        }
    }
}

Write-output ("{0} blobs removed from container {1}." –f $blobsremoved, $containerName);
}