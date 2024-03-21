


# get-addomaincontroller  -filter  *  |  %{
#     Get-WmiObject  -Namespace  "root/microsoftdfs"  -class  dfsrreplicatedfolderinfo  -ComputerName  $_.hostname
# }  |  ?{$_.replicationGroupName  -eq  "Domain  System  Volume"}  |  %{$_.cleanupConflictDirectory()}


$directoryPath = "C:\Temp\Jonathan"
$conflictFilePattern = '*-CentralServer-*.docx'
$conflictFiles = Get-ChildItem -Path $directoryPath -Filter $conflictFilePattern

foreach ($file in $conflictFiles) {
    if ($file.Name -match '-(\d+)\.docx$') {
        $versionNumber = [int]$matches[1]
        if ($versionNumber -gt 10) {
            Remove-Item $file.FullName -Force
            Write-Host "Deleted file: $($file.FullName)"
        }
    }
}