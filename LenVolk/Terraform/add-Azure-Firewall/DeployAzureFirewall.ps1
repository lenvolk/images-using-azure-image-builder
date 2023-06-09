# This script will add the following resources to the project:
# - An Azure Firewall instance in the hub network
# - An Azure Firewall policy
# - An Azure Firewall rule collection group
# - A route table

# You will need to assign subnets to the route table to allow the firewall to work.

# The Azure Firewall is expensive to run ($1.25/hour) 

#### Download Terraform
$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
$TerraformURI              = 'https://releases.hashicorp.com/terraform/1.3.7/terraform_1.3.7_windows_386.zip'
$TerraformInstaller             = 'TerraformSetup.zip'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $TerraformURI  -OutFile "$TerraformInstaller"

Expand-Archive `
    -LiteralPath ".\$TerraformInstaller" `
    -DestinationPath ".\" `
    -Force `
    -Verbose
Remove-Item $TerraformInstaller -Force

#### Authenticate to Portal
az logout
Disconnect-AzAccount
$subscription = "DemoSub"
Connect-AzAccount -Subscription $subscription 
az login --only-show-errors -o table --query Dummy
az account set -s $Subscription


#### Setup parameters
$hub_vnet_resource_group = "maintenance"
$vnetName = "maintenanceVNET"
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $hub_vnet_resource_group
$fw_subnet_id = (Get-AzVirtualNetworkSubnetConfig -Name "AzureFirewallSubnet" -VirtualNetwork $vnet).id


# Initialize terraform
terraform init 

# # Set the Subnet ID for the Azure Firewall
# # You can get the Subnet ID from the terraform output in the first directory
# $subnets = terraform -chdir="..\1-deploy-lab-environment" output -json subnets | ConvertFrom-Json
# $env:TF_VAR_fw_subnet_id = $subnets.AzureFirewallSubnet

# # Get the resource group for the Hub VNet
# $env:TF_VAR_hub_vnet_resource_group = terraform -chdir="..\1-deploy-lab-environment" output -raw vnet_resource_group

# Set up the Firewall
terraform apply -var hub_vnet_resource_group=$hub_vnet_resource_group -var fw_subnet_id=$fw_subnet_id -auto-approve

# Remove the Azure Firewall when you're done
# You'll need to remove any extra rules you added and subnet route assignments first
# terraform destroy

# Stop AzFW
# https://learn.microsoft.com/en-us/answers/questions/936825/is-it-possible-to-turn-off-the-azure-firewall-to-s
# Stop an existing firewall
$azfw = Get-AzFirewall -Name "avd-FW-eastus2" -ResourceGroupName $hub_vnet_resource_group
$azfw.Deallocate()
Set-AzFirewall -AzureFirewall $azfw

# Start the firewall
$azfw = Get-AzFirewall -Name "avd-FW-eastus2" -ResourceGroupName $hub_vnet_resource_group
$vnet = Get-AzVirtualNetwork -ResourceGroupName $hub_vnet_resource_group -Name $vnetName
$publicip1 = Get-AzPublicIpAddress -Name "avd-FW-eastus2" -ResourceGroupName $hub_vnet_resource_group
$azfw.Allocate($vnet,@($publicip1))

Set-AzFirewall -AzureFirewall $azfw