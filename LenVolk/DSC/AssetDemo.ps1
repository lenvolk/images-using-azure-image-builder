Configuration AssetDemo
{

$samplestr = Get-AutomationVariable –Name 'SampleString'

    Node "localhost"
    {
        File CreateDir {
            Type = "Directory"
            Ensure = "Present"
            DestinationPath = "C:\Temp1"
        }
        File CreateFile {
            DestinationPath = 'C:\Temp1\DSCAsset.txt'
            Ensure = "Present"
            Contents = $samplestr
        }
     
    }
}