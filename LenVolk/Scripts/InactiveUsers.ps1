# Ref https://learn.microsoft.com/en-us/answers/questions/880911/connect-msgraph-is-not-recognized-as-the-name-of-a
# open ISE as admin
# Install-Module Microsoft.Graph -Scope currentuser
# Import-Module Microsoft.Graph.Intune

Connect-MgGraph
 
$inactiveDate = (Get-Date).AddDays(-90)
 
$users = Get-MgUser -All:$true -Property Id, DisplayName, UserPrincipalName, UserType, SignInActivity | Where-Object { $_.AccountEnabled -eq $true }
 
$inactiveUsers = $users | Where-Object {
    $_.SignInActivity.LastSignInDateTime -lt $inactiveDate
} | Select-Object DisplayName, UserPrincipalName, UserType
 
$inactiveUsers | Export-Csv -Path 'outputfile.csv'