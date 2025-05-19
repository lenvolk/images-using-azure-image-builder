configuration LAMPServerUbuntu {
    Import-DSCResource -ModuleName nxtools
 
    Node localhost {
 
        # List of required packages (adjust package names as needed for Ubuntu)
        $requiredPackages = @("apache2", "php", "php-mysql", "mariadb-server")
        $enabledServices = @("apache2", "mariadb")
 
         #Ensure packages are installed
         ForEach ($package in $requiredPackages){
             nxPackage $Package{
                 Ensure = "Present"
                 Name = $Package
                 PackageType = "apt"
             }
         }
 
         #Ensure daemons are enabled
         ForEach ($service in $enabledServices){
             nxService $service{
                 Enabled = $true
                 Name = $service
                 Controller = "SystemD"
                 State = "running"
             }
         }
    }
 }

LAMPServerUbuntu