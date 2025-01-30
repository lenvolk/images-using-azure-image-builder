# Ref https://learn.microsoft.com/en-us/azure/automation/automation-dsc-onboarding#enable-physicalvirtual-windows-machines


Set-DscLocalConfigurationManager -Path C:\Temp\DscMetaConfigs -ComputerName ArcBox-Win2K19, ArcBox-Win2K22

# If executing remotely fails run in locally on the ARC Server
# Set-DscLocalConfigurationManager -Path c:\temp\DscMetaConfigs -Verbose -Force