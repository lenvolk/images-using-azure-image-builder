# Ref https://learn.microsoft.com/en-us/azure/automation/automation-dsc-onboarding#generate-dsc-metaconfigurations-using-azure-automation-cmdlets


$Params = @{
    ResourceGroupName = 'Automation'; # The name of the Resource Group that contains your Azure Automation account
    AutomationAccountName = 'ArcBox-Automation'; # The name of the Azure Automation account where you want a node on-boarded to
    ComputerName = @('ArcBox-Win2K19', 'ArcBox-Win2K22'); # The names of the computers that the metaconfiguration will be generated for
    OutputFolder = "C:\Temp\DSC\v2";
}
# Use PowerShell splatting to pass parameters to the Azure Automation cmdlet being invoked
# For more info about splatting, run: Get-Help -Name about_Splatting
Get-AzAutomationDscOnboardingMetaconfig @Params