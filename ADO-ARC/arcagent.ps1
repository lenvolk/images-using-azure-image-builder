

# Define the URL and file path   https://img.volk.bike/0116135136.png
$msiUrl = "https://aka.ms/AzureConnectedMachineAgent"
$msiPath = "C:\Support\Logs\AzureConnectedMachineAgent.msi"

# Create the folder if it doesn't exist
if (-not (Test-Path -Path "C:\Support\Logs")) {
    New-Item -ItemType Directory -Path "C:\Support\Logs"
}

# Download the MSI file
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

# Execute the MSI file
Start-Process msiexec.exe -ArgumentList "/i $msiPath /qn /l*v `"C:\Support\Logs\azcmagentupgradesetup.log`"" -Wait
