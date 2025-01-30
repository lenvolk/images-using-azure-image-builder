Configuration IIS_FileV2
{
    Node "localhost"
    {
        File DscFile {
            Type = "Directory"
            Ensure = "Present"
            DestinationPath = "C:\Temp1"
        }
          # hello world from file
        File HelloWorld {
            DestinationPath = "C:\Temp1\HelloWorld.txt"
            Ensure = "Present"
            Contents   = "Getting started with DSC!"
        }
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