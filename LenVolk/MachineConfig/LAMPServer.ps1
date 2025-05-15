
# GuestConfiguration module
# Install-Module -Name GuestConfiguration -Force -AllowClobber
#
# PSDscResources module
# Install-Module -Name PSDscResources -Repository PSGallery -Force -AllowClobber
#
# Install-Module -Name nx -Repository PSGallery -Force -AllowClobber

#Author a configuration
configuration LAMPServer {
    Import-DSCResource -ModuleName nx
 
    Node localhost {
 
         $requiredPackages = @("httpd","mod_ssl","php","php-mysqlnd","mariadb","mariadb-server")
         $enabledServices = @("httpd","mariadb")
 
         #Ensure packages are installed
         ForEach ($package in $requiredPackages){
             nxPackage $Package{
                 Ensure = "Present"
                 Name = $Package
                 PackageType = "yum"
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

# Get the current compliance results for the local machine
Get-GuestConfigurationPackageComplianceStatus -Path ./LAMPServer.zip
# Test applying the configuration to local machine
Start-GuestConfigurationPackageRemediation -Path ./LAMPServer.zip

#Create a policy definition that enforces a custom configuration package, in a specified path
$demoguid = New-Guid
$contentUri = "https://saarcscripts01.blob.core.windows.net/machine-configuration/LAMPServer.zip?sp=r&st=2025-03-10T15:20:02Z&se=2025-03-17T23:20:02Z&spr=https&sv=2022-11-02&sr=b&sig=GEbpze6%2FhckV7r6HAcQIpp%2FZ8aHiQ1CmA6DQvboMHPA%3D"

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