# Create a package that will only audit compliance
$params = @{
    Name          = 'TimeZone'
    Configuration = '.\TimeZoneCustom\localhost.mof'
    Type          = 'AuditandSet'
    Force         = $true
}
New-GuestConfigurationPackage @params