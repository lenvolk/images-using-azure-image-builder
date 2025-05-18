#Author a configuration
configuration LAMPServerUbuntu {
    Import-DSCResource -ModuleName nxtools
 
    Node localhost {
 
        # List of required packages (adjust package names as needed for Ubuntu)
        $requiredPackages = @("apache2", "php", "php-mysql", "mariadb-server")
        $enabledServices = @("apache2", "mariadb")
 
         #Ensure packages are installed
         ForEach ($package in $requiredPackages){
             nxPackage $Package{
                 Ensure = "Present"
                 Name = $Package
                 PackageType = "apt"
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

LAMPServerUbuntu

# Create a package that will audit and apply the configuration (Set)
$params = @{
    Name          = 'LAMPServerUbuntu'
    Configuration = './LAMPServerUbuntu/localhost.mof'
    Type          = 'AuditAndSet'
    Force         = $true
}
New-GuestConfigurationPackage @params

# Get the current compliance results for the local machine
Get-GuestConfigurationPackageComplianceStatus -Path ./LAMPServerUbuntu.zip
# Test applying the configuration to local machine
Start-GuestConfigurationPackageRemediation -Path ./LAMPServerUbuntu.zip

#Create a policy definition that enforces a custom configuration package, in a specified path
$demoguid = New-Guid
$contentUri = "https://saarcscripts01.blob.core.windows.net/machine-configuration/LAMPServerUbuntu.zip?xxxxxxx"

$PolicyConfig      = @{
    PolicyId      = $demoguid
    ContentUri    = $contentUri
    DisplayName   = "LAMP server configuration (Ubuntu)"
    Description   = "Configures Apache HTTP Server, MySQL, and PHP on an Ubuntu Linux machine"
    Path          = "./policies/deployIfNotExists.json"
    Platform      = "Linux"
    PolicyVersion = "1.0.0"
    Mode          = "ApplyAndAutoCorrect"
    Tag           = @{
        InstallLampUbuntu = "true"
    }
  }
  
  New-GuestConfigurationPolicy @PolicyConfig

  New-AzPolicyDefinition -Name 'lamppolicyubuntu' -Policy '.\policies\deployIfNotExists.json\LAMPServerUbuntu_DeployIfNotExists.json'