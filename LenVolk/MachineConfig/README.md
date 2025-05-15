# LAMP Server Configuration using PowerShell DSC

This directory contains a PowerShell Desired State Configuration (DSC) script for configuring a LAMP (Linux, Apache, MySQL, PHP) server on RHEL/CentOS systems.

## Prerequisites

Before running the LAMPServer.ps1 script, make sure you have the following PowerShell modules installed:

### Required PowerShell Modules

| Module Name | Description | Installation Command |
|-------------|-------------|----------------------|
| PSDesiredStateConfiguration | Core DSC module that enables the `Import-DSCResource` functionality | `Install-Module -Name PSDesiredStateConfiguration -Force -AllowClobber` |
| GuestConfiguration | Module for creating and managing guest configurations in Azure | `Install-Module -Name GuestConfiguration -Repository PSGallery -Force -AllowClobber` |
| nx | Linux DSC resources for managing packages, services, files, etc. | `Install-Module -Name nx -Repository PSGallery -Force -AllowClobber` |
| PSDscResources | Additional DSC resources | `Install-Module -Name PSDscResources -Repository PSGallery -Force -AllowClobber` |

### Installation Script

You can use the following PowerShell script to install all the required modules:

```powershell
# Install required modules
Install-Module -Name PSDesiredStateConfiguration -Force -AllowClobber
Install-Module -Name GuestConfiguration -Repository PSGallery -Force -AllowClobber
Install-Module -Name nx -Repository PSGallery -Force -AllowClobber
Install-Module -Name PSDscResources -Repository PSGallery -Force -AllowClobber
```

## Script Functionality

The `LAMPServer.ps1` script:

1. Defines a DSC configuration that ensures the following packages are installed on a Linux system:
   - httpd (Apache)
   - mod_ssl
   - php
   - php-mysqlnd
   - mariadb
   - mariadb-server

2. Ensures that these services are enabled and running:
   - httpd
   - mariadb

3. Creates a DSC configuration package that can be used for:
   - Auditing systems for compliance
   - Remediating non-compliant systems

4. Creates an Azure Policy definition that can be used to enforce this configuration across your Azure environment

## Usage

1. Install the required PowerShell modules as described above
2. Run the `LAMPServer.ps1` script
3. The script will:
   - Generate a MOF file in the LAMPServer directory
   - Create a guest configuration package (.zip file)
   - Generate a policy definition file

## Azure Integration

The script includes functionality to:

1. Test the configuration locally
2. Create an Azure Policy definition
3. Upload the configuration package to Azure Blob Storage
4. Create an Azure Policy that enforces the LAMP configuration on Linux VMs

## Notes

- This configuration uses the nx module's resources which are designed for Linux systems
- The script assumes a RHEL/CentOS-based system (uses yum package manager)
- The generated policy uses the "ApplyAndAutoCorrect" mode, which will automatically remediate any non-compliant systems
