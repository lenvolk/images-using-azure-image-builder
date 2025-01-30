param (
    [string]$resourceGroup,
    [string]$hostPool,
    [string]$appgrp
)


###
# Get active sessions on all the Session Host
$sessionHosts = (Get-AzWvdSessionHost -ResourceGroupName $resourceGroup -HostPoolName $hostPool | Select-Object Name, AllowNewSession, Session) 


# Enable drain mode on the Session Host
foreach ($sessionHost in $sessionHosts) {
    Update-AzWvdSessionHost -ResourceGroupName $resourceGroup -HostPoolName $hostPool -SessionHostName $sessionHost.Name.Split("/")[1] -AllowNewSession:$false
}

foreach ($sessionHost in $sessionHosts) {
    if ( $sessionHost.Session) {  
        $ActiveSH = $sessionHost.Name.Split("/")[1]
    }
}

###
# Get active sessions on a Session Host
if ( $ActiveSH ) {
    $ActiveSessions = 
    foreach ($sessionHostName in $ActiveSH) {
        Get-AzWvdUserSession -ResourceGroupName $resourceGroup -HostPoolName $hostPool -SessionHostName $ActiveSH | Select-Object UserPrincipalName, Name, ID | Sort-Object Name
    }


    if ( $ActiveSessions ) {
        # Send a message to all users on the Session Host session
        foreach ($ActiveSessionHost in $ActiveSessions) {
            $userMessage = @{
                HostPoolName      = $hostPool
                ResourceGroupName = $resourceGroup
                SessionHostName   = $ActiveSessionHost.Name.Split("/")[1]
                UserSessionId     = ($ActiveSessionHost.id -split '/')[-1]
                MessageTitle      = "Time to Log Off"
                MessageBody       = "The system will shut down in 1 minute.  Save and exit."
            }
            Send-AzWvdUserSessionMessage @userMessage

        }

        Start-Sleep -Seconds 60

        # Remove all user sessions from a Session Host
        foreach ($ActiveSessionHost in $ActiveSessions) {
            $removeSession = @{
                HostPoolName      = $hostPool
                ResourceGroupName = $resourceGroup
                SessionHostName   = $ActiveSessionHost.Name.Split("/")[1]
                UserSessionId     = ($ActiveSessionHost.id -split '/')[-1]
            }
            Remove-AzWvdUserSession @removeSession
        }

    } #end of ActiveSessions
} #end of ActiveSH

else {
    write-host "WVD pool has no active connections"
}

###

# Remove a Session Host
# foreach ($sessionHost in $sessionHosts) {
#     Remove-AzWvdSessionHost -ResourceGroupName $resourceGroup -HostPoolName $hostPool -Name $sessionHost.Name.Split("/")[1]
# }

#############################################################

# Get the Application Groups
$appGroups = Get-AzWvdApplicationGroup -ResourceGroupName $resourceGroup

# Remove the Application Groups
foreach ($appGroup in $appGroups) {
    Remove-AzWvdApplicationGroup -Name $appGroup.Name -ResourceGroupName $resourceGroup
    Write-Output "Removed: $($appGroup.name)"
}

# Remove the Host Pool
Remove-AzWvdHostPool -Name $hostPool -ResourceGroupName $resourceGroup -Force:$true

# Remove the Resource Group
# View items in the Resource Group
Get-AzResource -ResourceGroupName $resourceGroup | Select-Object Name, ResourceGroupName

# Optional, be sure nothing in the Resource Group is still in use
Remove-AzResourceGroup -Name $resourceGroup -Force

# # # View existing Resource Groups
# # Get-AzResourceGroup | Select-Object ResourceGroupName
