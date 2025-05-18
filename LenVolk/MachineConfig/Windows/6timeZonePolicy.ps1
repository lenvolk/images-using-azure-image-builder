# No MSI
$PolicyConfig = @{
    PolicyId                 = (New-Guid).Guid # Or a predefined GUID
    ContentUri               = 'https://sharexvolkbike.blob.core.windows.net/machine-configuration/TimeZone.zip?xxxxxx' # URI of your uploaded package
    DisplayName              = 'Windows TimeZone EST Policy'
    Description              = 'AuditAndSet to ensure VMs are set to Eastern Standard Time.'
    Path                     = '.\policies' # Local directory to save generated policy files
    Platform                 = 'Windows' # Can be 'Windows' or 'Linux'
    PolicyVersion            = '1.0.0'
    Mode                     = 'ApplyAndAutoCorrect' # Other options: 'Audit', 'ApplyAndMonitor'
    Tag           = @{
        AdjustTimeZone = "true"
    }
}
New-GuestConfigurationPolicy @PolicyConfig # Add -ExcludeArcMachines if MI is used and Arc support for it is limited for this scenario

New-AzPolicyDefinition -Name 'Windows TimeZone EST MachineConfig' -Policy '.\policies\TimeZone_DeployIfNotExists.json' -ManagementGroupName 'volk'


# with MSI

$PolicyConfig = @{
    PolicyId                 = (New-Guid).Guid # Or a predefined GUID
    ContentUri               = 'YOUR_BLOB_STORAGE_URI/TimeZone.zip' # URI of your uploaded package
    DisplayName              = 'Windows MSI TimeZone EST Policy'
    Description              = 'AuditAndSet to ensure VMs are set to Eastern Standard Time.'
    Path                     = '.\policies' # Local directory to save generated policy files
    Platform                 = 'Windows' # Can be 'Windows' or 'Linux'
    PolicyVersion            = '1.0.0'
    Mode                     = 'ApplyAndAutoCorrect' # Other options: 'Audit', 'ApplyAndMonitor'
    LocalContentPath         = '.\TimeZone.zip' # Path to the local .zip for hash generation
    ManagedIdentityResourceId = '$ManagedIdentityResourceId' # Optional: Resource ID of the user-assigned managed identity if using private storage
}
New-GuestConfigurationPolicy @PolicyConfig -ExcludeArcMachines # Add -ExcludeArcMachines if MI is used and Arc support for it is limited for this scenario