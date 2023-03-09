
Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online

# Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State