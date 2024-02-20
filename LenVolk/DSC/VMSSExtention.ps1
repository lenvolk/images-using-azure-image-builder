# Ref https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-deploy-app#install-an-app-to-a-windows-vm-with-powershell-dsc

# Define the script for your Desired Configuration to download and run
$dscConfig = @{
    "wmfVersion" = "latest";
    "configuration" = @{
      "url" = "https://github.com/Azure-Samples/compute-automation-configurations/raw/master/dsc.zip";
      "script" = "configure-http.ps1";
      "function" = "WebsiteTest";
    };
  }
  
  # Get information about the scale set
  $vmss = Get-AzVmss `
                  -ResourceGroupName "VMSS" `
                  -VMScaleSetName "VMSS-DSC"
  
  # Add the Desired State Configuration extension to install IIS and configure basic website
  $vmss = Add-AzVmssExtension `
      -VirtualMachineScaleSet $vmss `
      -Publisher Microsoft.Powershell `
      -Type DSC `
      -TypeHandlerVersion 2.24 `
      -Name "DSC" `
      -Setting $dscConfig
  
  # Update the scale set and apply the Desired State Configuration extension to the VM instances
  Update-AzVmss `
      -ResourceGroupName "VMSS" `
      -Name "VMSS-DSC"  `
      -VirtualMachineScaleSet $vmss

# Because in Flex VMSS the upgrade policy  is manual
Get-AzVmssVM -ResourceGroupName "VMSS" -VMScaleSetName "VMSS-DSC" -InstanceId $ID
Update-AzVmssInstance -ResourceGroupName "VMSS" -VMScaleSetName "VMSS-DSC" -InstanceId "VMSS-DSC_e8718718"

# Custom extention script
# https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/tutorial-install-apps-powershell#create-custom-script-extension-definition