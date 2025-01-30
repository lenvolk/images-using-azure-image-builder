### Set Drain Mode on the Session Hosts ###

# Connect to Azure AD
Connect-AzAccount

# Get current connection status
Get-AzContext

# Get Session Hosts drain mode status
Get-AzWvdSessionHost -ResourceGroupName Lab2HPRG -HostPoolName Lab2HP | Select-Object Name,AllowNewSession

# Enable drain mode on the Session Host
Update-AzWvdSessionHost -ResourceGroupName Lab2HPRG -HostPoolName Lab2HP -SessionHostName Lab2SH-1.ciraltoslab.com -AllowNewSession:$false







### Remote the Session Host ###

# Set some variables first
$resourceGroup = "ResourceGroupName"
$hostPool = "HostPoolName"
$sessionHost = "SessionHostName"

# Get active sessions on all the Session Host
Get-AzWvdSessionHost -ResourceGroupName $resourceGroup -HostPoolName $hostPool | Select-Object Name,AllowNewSession,Session

# Get active sessions on a Session Host
Get-AzWvdUserSession -ResourceGroupName $resourceGroup -HostPoolName $hostPool -SessionHostName $sessionHost | Select-Object UserPrincipalName,Name,ID | Sort-Object Name

# Send a message to all users on the Session Host session
$sessions = Get-AzWvdUserSession -ResourceGroupName $resourceGroup -HostPoolName $hostPool -SessionHostName $sessionHost
foreach ($session in $sessions) {
    $userMessage = @{
        HostPoolName = $hostPool
        ResourceGroupName = $resourceGroup
        SessionHostName = $sessionHost
        UserSessionId = ($session.id -split '/')[-1]
        MessageTitle = "Time to Log Off"
        MessageBody = "The system will shut down in 1 minute.  Save and exit."
    }
    Send-AzWvdUserSessionMessage @userMessage
}

# Remove all user sessions from a Session Host
$sessions = Get-AzWvdUserSession -ResourceGroupName $resourceGroup -HostPoolName $hostPool -SessionHostName $sessionHost
foreach ($session in $sessions) {
    $removeSession = @{
        HostPoolName = $hostPool
        ResourceGroupName = $resourceGroup
        SessionHostName = $sessionHost
        UserSessionId = ($session.id -split '/')[-1]
    }
    Remove-AzWvdUserSession @removeSession
}

# Remove a Session Host
Remove-AzWvdSessionHost -ResourceGroupName $resourceGroup -HostPoolName $hostPool -Name $sessionHost