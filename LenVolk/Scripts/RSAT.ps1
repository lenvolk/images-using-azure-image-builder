
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online

# Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State

# on the server
# Install-WindowsFeature -Name RSAT-Hyper-V-Tools
# Install-WindowsFeature DNS -IncludeManagementTools
# Install-WindowsFeature DHCP -IncludeManagementTools
# Install-WindowsFeature Failover-Clustering
# Install-WindowsFeature File-Services