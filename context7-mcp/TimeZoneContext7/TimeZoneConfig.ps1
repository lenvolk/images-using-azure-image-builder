Configuration SimpleTimeZone {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TimeZoneValue
    )
    
    Import-DscResource -ModuleName ComputerManagementDsc
    
    Node localhost {
        TimeZone SetTimeZone {
            IsSingleInstance = 'Yes'
            TimeZone = $TimeZoneValue
        }
    }
}
