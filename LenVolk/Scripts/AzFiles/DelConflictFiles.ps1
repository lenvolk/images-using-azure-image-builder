
# Ref: https://learn.microsoft.com/en-us/azure/storage/files/storage-files-faq
# For example, the first conflict of CompanyReport.docx would become CompanyReport-CentralServer.docx if CentralServer is where the older write occurred. 
# The second conflict would be named CompanyReport-CentralServer-1.docx. Azure File Sync supports 100 conflict files per file. 
# Once the maximum number of conflict files is reached, the file will fail to sync until the number of conflict files is less than 100.

# get-addomaincontroller  -filter  *  |  %{
#     Get-WmiObject  -Namespace  "root/microsoftdfs"  -class  dfsrreplicatedfolderinfo  -ComputerName  $_.hostname
# }  |  ?{$_.replicationGroupName  -eq  "Domain  System  Volume"}  |  %{$_.cleanupConflictDirectory()}


$directoryPath = "C:\Temp\share"
$conflictFilePattern = "*-$env:COMPUTERNAME-*.docx"
$conflictFiles = Get-ChildItem -Path $directoryPath -Filter $conflictFilePattern

if ($conflictFiles.Name -match "-(\d+)\.docx")
{
    foreach ($file in $conflictFiles) {
        if ($file.Name -match "-(\d+)\.docx$") {
            $versionNumber = [int]$matches[1]
            if ($versionNumber -gt 10 -and $versionNumber -lt 80) {
                # Do something with the file
                Write-Host "Found file: $($file.FullName)"
            }
        }
    }
}