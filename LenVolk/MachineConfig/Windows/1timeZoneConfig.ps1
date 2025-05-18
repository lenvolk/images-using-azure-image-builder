
# Ref https://learn.microsoft.com/en-us/azure/governance/machine-configuration/overview


# Pre Requisites
# https://learn.microsoft.com/en-us/azure/governance/machine-configuration/overview#deploy-requirements-for-azure-virtual-machines
# Initiative "Deploy prerequisites to enable Guest Configuration policies on virtual machines"

Configuration TimeZoneCustom {
    Import-DscResource -ModuleName ComputerManagementDsc -Name TimeZone
    TimeZone TimeZoneConfig {
        TimeZone = 'Eastern Standard Time'
        IsSingleInstance = 'Yes'
    }
}

TimeZoneCustom