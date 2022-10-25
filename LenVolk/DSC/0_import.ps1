
# IMPORT THE CONFIGURATION
$grp="automation"
Import-AzAutomationDscConfiguration -Published -ResourceGroupName $grp -SourcePath ./file.ps1 -Force -AutomationAccountName Automation