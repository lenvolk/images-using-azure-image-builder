#Author a configuration
configuration LAMPServerRHEL {
    Import-DSCResource -ModuleName nxtools
 
    Node localhost {
 
         $requiredPackages = @("httpd","mod_ssl","php","php-mysqlnd","mariadb","mariadb-server")
         $enabledServices = @("httpd","mariadb")
 
         #Ensure packages are installed
         ForEach ($package in $requiredPackages){
             nxPackage $Package{
                 Ensure = "Present"
                 Name = $Package
                 PackageType = "yum"
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

LAMPServerRHEL