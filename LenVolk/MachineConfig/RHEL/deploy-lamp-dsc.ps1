
# Install-Module -Name nxtools -Force -AllowClobber

.\LAMPConfig.ps1

# Create a package that will audit and apply the configuration (Set)
$params = @{
    Name          = 'LAMPServer'
    Configuration = './LAMPServerRHEL/localhost.mof'
    Type          = 'AuditAndSet'
    Force         = $true
}
New-GuestConfigurationPackage @params

# Before running the next command, ensure that teh package is uploaded to a storage account
# and that the SAS URL is available.

#Create a policy definition that enforces a custom configuration package, in a specified path
$demoguid = New-Guid
$contentUri = "SAS URL to the LAMPServer package"

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

  New-AzPolicyDefinition -Name 'lamppolicyrhel' -Policy '.\policies\deployIfNotExists.json\LAMPServer_DeployIfNotExists.json' -ManagementGroupName 'volk'