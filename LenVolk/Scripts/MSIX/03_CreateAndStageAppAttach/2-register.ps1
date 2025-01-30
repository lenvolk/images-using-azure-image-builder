#MSIX app attach registration sample
#region variables 
$packageName = "<Full package name>" 

$path = "C:\Program Files\WindowsApps\" + $packageName + "\AppxManifest.xml"
#endregion

#region register
Add-AppxPackage -Path $path -DisableDevelopmentMode -Register
#endregion 