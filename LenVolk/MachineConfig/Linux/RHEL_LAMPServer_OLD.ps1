
# REF https://learn.microsoft.com/en-us/azure/automation/quickstarts/dsc-configuration
#Author a configuration
configuration LAMPServer {
    Import-DSCResource -ModuleName nx
 
    Node localhost {
 
         $requiredPackages = @("httpd","mod_ssl","php","php-mysqlnd","mariadb","mariadb-server")
         $enabledServices = @("httpd","mariadb")         #Ensure packages are installed
         ForEach ($package in $requiredPackages){
             nxPackage $Package{
                 Ensure = "Present"
                 Name = $Package
                 PackageManager = "yum"
             }
         }
 
         #Ensure daemons are enabled
         ForEach ($service in $enabledServices){
             nxService $service{
                 Enabled = $true
                 Name = $service
                 Controller = "SystemD"
                 State = "running"
             }
         }
    }
 }

LAMPServer

# Create a package that will audit and apply the configuration (Set)
$params = @{
    Name          = 'LAMPServer'
    Configuration = './LAMPServer/localhost.mof'
    Type          = 'AuditAndSet'
    Force         = $true
}
New-GuestConfigurationPackage @params

# # Get the current compliance results for the local machine
# Get-GuestConfigurationPackageComplianceStatus -Path ./LAMPServer.zip
# # Test applying the configuration to local machine
# Start-GuestConfigurationPackageRemediation -Path ./LAMPServer.zip

#Create a policy definition that enforces a custom configuration package, in a specified path
$demoguid = New-Guid
$contentUri = "https://sharexvolkbike.blob.core.windows.net/machine-configuration/LAMPServer.zip?"

$PolicyConfig      = @{
    PolicyId      = $demoguid
    ContentUri    = $contentUri
    DisplayName   = "LAMP server configuration (RHEL)"
    Description   = "Configures Apache HTTP Server, MySQL, and PHP on RHEL Linux machine"
    Path          = "./policies/deployIfNotExists.json"
    Platform      = "Linux"
    PolicyVersion = "1.0.0"
    Mode          = "ApplyAndAutoCorrect"
    Tag           = @{
        InstallLampRHEL = "true"
    }
  }
  
  New-GuestConfigurationPolicy @PolicyConfig
  New-AzPolicyDefinition -Name 'lamppolicy' -Policy '.\policies\deployIfNotExists.json\LAMPServer_DeployIfNotExists.json'