Configuration IIS_File
{
    # This will generate two .mof files; FileSrvE2.mof, FileSrv2E2.mof
    Node ('FileSrvE2', 'FileSrv2E2')
    {
        #ensure IIS is installed
        WindowsFeature IIS
        {
            Name = 'web-server'
            Ensure = 'Present'
        }

        #ensure the default document is configured for web app
        File default
        {
          DestinationPath = 'c:\inetpub\wwwroot\default.htm'
          Contents = 'Hello World'
          DependsOn = '[WindowsFeature]IIS'
          Ensure = 'Present'
        }
    }
}