Configuration LAMPConfig {
    Import-DscResource -ModuleName 'nx'
    
    Node localhost {
        # Install Apache
        nxPackage apache2 {
            Name = "apache2"
            Ensure = "Present"
            PackageManager = "apt"
        }
        
        # Install MySQL
        nxPackage mysql {
            Name = "mysql-server"
            Ensure = "Present"
            PackageManager = "apt"
        }
        
        # Install PHP
        nxPackage php {
            Name = "php"
            Ensure = "Present"
            PackageManager = "apt"
        }
        
        # Install PHP MySQL extension
        nxPackage php_mysql {
            Name = "php-mysql"
            Ensure = "Present"
            PackageManager = "apt"
        }
        
        # Enable Apache service
        nxService apache {
            Name = "apache2"
            Controller = "systemd"
            Enabled = $true
            State = "running"
        }
        
        # Enable MySQL service
        nxService mysql_service {
            Name = "mysql"
            Controller = "systemd"
            Enabled = $true
            State = "running"
        }
        
        # Create a test PHP file
        nxFile phpinfo {
            DestinationPath = "/var/www/html/info.php"
            Contents = "<?php\nphpinfo();\n?>"
            Ensure = "Present"
            Type = "File"
            Mode = "0644"
        }
    }
}

LAMPConfig
