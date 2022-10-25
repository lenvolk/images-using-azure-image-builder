Configuration File {
  
    Import-DscResource -ModuleName PsDesiredStateConfiguration
  
    Node "localhost" {
      
      # hello world from file
      File HelloWorld {
          DestinationPath = "C:\Temp\HelloWorld.txt"
          Ensure = "Present"
          Contents   = "Getting started with DSC!"
      }
  
    }
  }