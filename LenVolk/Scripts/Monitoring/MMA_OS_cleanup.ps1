#Ref
# Uninstall agent https://learn.microsoft.com/en-us/azure/azure-monitor/agents/agent-manage?tabs=PowerShellLinux#uninstall-agent
# Extention https://learn.microsoft.com/en-us/powershell/module/az.compute/remove-azvmextension?view=azps-9.4.0&viewFallbackFrom=azps-9.1.0


#Variables
$PathToCsv = "C:\Temp\MMA_VMs.csv"
$computers = (Import-Csv -Path $PathToCsv).vmname

# Download from https://go.microsoft.com/fwlink/?LinkId=828603
$sourcefile = "\\server01\LAWShare\MMASetup-AMD64.exe"
#This section will uninstall the MMA 
foreach ($computer in $computers) 
{
    $destinationFolder = "\\$computer\C$\Temp"
    #It will copy $sourcefile to the $destinationfolder. If the Folder does not exist it will create it.
 
    if (!(Test-Path -path $destinationFolder))
    {
        New-Item $destinationFolder -Type Directory
    }
    Copy-Item -Path $sourcefile -Destination $destinationFolder
    Invoke-Command -ComputerName $computer `
                   -ScriptBlock {Start-Process 'c:\temp\MMASetup-AMD64.exe /Q'}
}
 
# Linux 
# wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh --purge

# We can run the same task in parallel if you have a server with PS 7 installed 
 
# $computers | ForEach-Object -Parallel {
# Invoke-Command `
#    -ComputerName $_.Name `
#    -ScriptBlock {Start-Process 'c:\temp\MMASetup-AMD64.exe /qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=1 OPINSIGHTS_WORKSPACE_ID="<your workspace ID>" OPINSIGHTS_WORKSPACE_KEY="<your workspace key>" AcceptEndUserLicenseAgreement=1'}
# }