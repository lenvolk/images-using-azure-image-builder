Configuration File {
  
    Import-DscResource -ModuleName PsDesiredStateConfiguration
  
    Node "localhost" {
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
  
    }
  }