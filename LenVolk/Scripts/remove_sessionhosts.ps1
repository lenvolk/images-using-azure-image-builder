param (
    [string]$HPResourceGroup,
    [string]$HPName,
    [string]$OldVmResourceGroup
)

###
# Get active sessions on all the Session Host
$sessionHosts = (Get-AzWvdSessionHost -ResourceGroupName $HPResourceGroup -HostPoolName $HPName | Select-Object Name, AllowNewSession, Session) 


# Enable drain mode on the Session Host
foreach ($sessionHost in $sessionHosts) {
    Update-AzWvdSessionHost -ResourceGroupName $HPResourceGroup -HostPoolName $HPName -SessionHostName $sessionHost.Name.Split("/")[1] -AllowNewSession:$false
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
        Get-AzWvdUserSession -ResourceGroupName $HPResourceGroup -HostPoolName $HPName -SessionHostName $ActiveSH | Select-Object UserPrincipalName, Name, ID | Sort-Object Name
    }


    if ( $ActiveSessions ) {
        # Send a message to all users on the Session Host session
        foreach ($ActiveSessionHost in $ActiveSessions) {
            $userMessage = @{
                HostPoolName      = $HPName
                ResourceGroupName = $HPResourceGroup
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
                HostPoolName      = $HPName
                ResourceGroupName = $HPResourceGroup
                SessionHostName   = $ActiveSessionHost.Name.Split("/")[1]
                UserSessionId     = ($ActiveSessionHost.id -split '/')[-1]
            }
            Remove-AzWvdUserSession @removeSession
        }

    } #end of ActiveSessions
} #end of ActiveSH

else {
    write-host "WVD pool has no active connections."
}

#Start VMs to allow TF destroy to work
$vms = (Get-AzVM -ResourceGroupName wvd-persistent-hp-rg)
$vms | ForEach-Object -Parallel {
    try {
        # Start the VM
        start-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -ErrorAction Stop -NoWait
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ("Error starting the VM: " + $ErrorMessage)
        Break
    }
}

$sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $HPResourceGroup -HostPoolName $HPName
$vmNames = (Get-AzVM -ResourceGroupName wvd-persistent-hp-rg | Select-Object Name)
$sessionHosts | ForEach-Object {
    # $vmNames.name -contains $_.ResourceId.Split("/")[8]
    try {
        if ($vmNames.name -contains $_.ResourceId.Split("/")[8]) {
            Remove-AzWvdSessionHost -ResourceGroupName $HPResourceGroup -HostPoolName $HPName -Name $_.Name.Split("/")[1]
        }
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ("Error removing the session host: " + $ErrorMessage)
        Break
    }
}