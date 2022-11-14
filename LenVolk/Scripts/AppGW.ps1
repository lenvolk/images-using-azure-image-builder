# Ref: https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-ssl-powershell
$RGname = "myResourceGroupAG"
$locName = "eastus"
az group create --name $RGname --location $locName

#Create Network Resources
$backendSubnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name myBackendSubnet `
  -AddressPrefix 10.0.1.0/24

$agSubnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name myAGSubnet `
  -AddressPrefix 10.0.2.0/24

$vnet = New-AzVirtualNetwork `
  -ResourceGroupName myResourceGroupAG `
  -Location eastus `
  -Name myVNet `
  -AddressPrefix 10.0.0.0/16 `
  -Subnet $backendSubnetConfig, $agSubnetConfig

# $pip = New-AzPublicIpAddress `
#   -ResourceGroupName myResourceGroupAG `
#   -Location eastus `
#   -Name myAGPublicIPAddress `
#   -AllocationMethod Static `
#   -Sku Standard


# Get Azure Application Gateway
$appgw=Get-AzApplicationGateway -Name appgw -ResourceGroupName $RGname
# Stop the Azure Application Gateway
Stop-AzApplicationGateway -ApplicationGateway $appgw
# Start the Azure Application Gateway (optional)
Start-AzApplicationGateway -ApplicationGateway $appgw
# remove cert
# Get-AzApplicationGatewaySslCertificate -ApplicationGateway $appgw
# Remove-AzApplicationGatewaySslCertificate -ApplicationGateway $appgw -Name "lvolk"
# Set-AzApplicationGateway -ApplicationGateway $appgw
# Get-AzApplicationGatewayHttpListener -ApplicationGateway $appgw | Select-Object Name
# Get-AzApplicationGatewayTrustedRootCertificate -ApplicationGateway $appgw

$VMs="General","Images","Video"
foreach($vm in $VMs) {
    Stop-AzVM -ErrorAction Stop -ResourceGroupName $RGname -Name $vm -Force -NoWait | Out-Null
}

foreach($vm in $VMs) {
    Start-AzVM -ErrorAction Stop -ResourceGroupName $RGname -Name $vm -NoWait
}
######################
$VM_User = "aibadmin"
$WinVM_Password = "P@ssw0rdP@ssw0rd"
$vnetName = "myVNet"
$subnetName = "myBackendSubnet"

$VMIP_Gen=( az vm create --no-wait --resource-group $RGname --name "General" `
                    --admin-username $VM_User --admin-password $WinVM_Password `
                    --image 'Win2022Datacenter' --location $locName `
                    --size 'Standard_B2ms' --tags 'AppGW' `
                    --vnet-name $vnetName `
                    --subnet $subnetName `
                    --nsg '""' `
                    --public-ip-sku Standard `
                    --query publicIpAddress -o tsv)
$VMIP_Images=( az vm create --no-wait --resource-group $RGname --name "Images" `
                    --admin-username $VM_User --admin-password $WinVM_Password `
                    --image 'Win2022Datacenter' --location $locName `
                    --size 'Standard_B2ms' --tags 'AppGW' `
                    --vnet-name $vnetName `
                    --subnet $subnetName `
                    --nsg '""' `
                    --public-ip-sku Standard `
                    --query publicIpAddress -o tsv)
$VMIP_Video=( az vm create --resource-group $RGname --name "Video" `
                    --admin-username $VM_User --admin-password $WinVM_Password `
                    --image 'Win2022Datacenter' --location $locName `
                    --size 'Standard_B2ms' --tags 'AppGW' `
                    --vnet-name $vnetName `
                    --nsg '""' `
                    --subnet $subnetName `
                    --public-ip-sku Standard `
                    --query publicIpAddress -o tsv)

$RunningVMs = (get-azvm -ResourceGroupName $RGname -Status) | Where-Object { $_.PowerState -eq "VM running" -and $_.StorageProfile.OsDisk.OsType -eq "Windows" } 
$RunningVMs | ForEach-Object -Parallel {
    Invoke-AzVMRunCommand `
        -ResourceGroupName $_.ResourceGroupName `
        -VMName $_.Name `
        -CommandId 'RunPowerShellScript' `
        -ScriptPath './IIS.ps1'
}
##########################################################################
# $VmName ="GeneralPublicIP"
# $VMIP=(Get-AzPublicIpAddress -ResourceGroupName $RGname -Name $VmName).IpAddress
# Connect to VM General
cmdkey /generic:$VMIP_Gen /user:$VM_User /pass:$WinVM_Password
mstsc /v:$VMIP_Gen /w:1440 /h:900
# Connect to VM Images
cmdkey /generic:$VMIP_Images /user:$VM_User /pass:$WinVM_Password
mstsc /v:$VMIP_Images /w:1440 /h:900
# Connect to VM Video
cmdkey /generic:$VMIP_Video /user:$VM_User /pass:$WinVM_Password
mstsc /v:$VMIP_Video /w:1440 /h:900

# # Delete RG
# Remove-AzResourceGroup -Name $RGname -Force