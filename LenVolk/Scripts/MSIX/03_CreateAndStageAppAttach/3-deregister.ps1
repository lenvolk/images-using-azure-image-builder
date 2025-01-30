#MSIX app attach deregistration sample
#region variables 
$packageName = "<Full package name>" 
#endregion

#region derregister
Remove-AppxPackage -PreserveRoamableApplicationData $packageName 
#endregion 