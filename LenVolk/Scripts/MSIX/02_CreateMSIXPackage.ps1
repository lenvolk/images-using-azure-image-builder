# 7Zip Download
# https://www.7-zip.org/download.html
# MSIX Packaging Tool Download
# https://docs.microsoft.com/en-us/windows/msix/packaging-tool/tool-overview
# Time stamp URL
# http://timestamp.verisign.com/scripts/timstamp.dll

# Add the package to the OS
Add-AppxPackage 'C:\Temp\7ZIPMSIXPackage\7ZIPMSIX.msix'

# Get the appx
Get-AppxPackage | where-object { $_.name -like "*7ZIP*" }

# Remove with the PackageFullName
Remove-AppxPackage -Package 7ZipPackage_1.0.0.0_x64__vztngq9shf2p2 #<FullPackageName>
