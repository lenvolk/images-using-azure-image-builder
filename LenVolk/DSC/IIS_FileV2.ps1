Configuration IIS_FileV2
{
    Node "localhost"
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