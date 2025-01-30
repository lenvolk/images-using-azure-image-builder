
# AZ CLI
## az cloud set --name AzureUSGovernment
## az cloud set --name AzureCloud
# az login --only-show-errors -o table --query Dummy
# $subscription = "DemoSub"
# az account set -s $Subscription
# az logout

# Info Prices https://learn.microsoft.com/en-us/azure/virtual-machines/spot-vms#pricing-and-eviction-history
# Info WorkLoad https://learn.microsoft.com/en-us/azure/architecture/guide/spot/spot-eviction

$rg_name="SpotVMResourceGroup"
$location="eastus"
$vnet_name="spotworkloadvnet"
$subnet_name="spotworkloadsubnet"
$subnet_prefix="10.0.0.0/24"
$nsg_name="spotworkloadnsg"
$vm1_name="deallocateVM"
$vm2_name="deleteVM"
$image="win2016datacenter"
$admin_username="localadmin"
$admin_password="P@ssw0rdP@ssw0rd" 


# Create a new resource group
az group create --name $rg_name --location $location

# Create a new virtual network
az network vnet create --resource-group $rg_name --name $vnet_name --address-prefixes 10.0.0.0/16

# Create a new subnet
az network vnet subnet create --resource-group $rg_name --vnet-name $vnet_name --name $subnet_name --address-prefixes $subnet_prefix

# Create a new network security group
az network nsg create --resource-group $rg_name --name $nsg_name

# Allow RDP traffic to the network security group
az network nsg rule create --resource-group $rg_name --nsg-name $nsg_name --name RDP --protocol tcp --priority 1000 --destination-port-ranges 3389



# Create VM with Deallocate eviction policy
az vm create `
    --resource-group $rg_name `
    --name $vm1_name `
    --image $image `
    --admin-username $admin_username `
    --admin-password $admin_password `
    --size Standard_D2_v3 `
    --vnet-name $vnet_name `
    --subnet $subnet_name `
    --nsg $nsg_name `
    --priority Spot `
    --max-price -1 `
    --public-ip-address-allocation Dynamic `
    --public-ip-sku Basic `
    --eviction-policy Deallocate

# Create VM with Delete eviction policy
az vm create `
    --resource-group $rg_name `
    --name $vm2_name `
    --image $image `
    --admin-username $admin_username `
    --admin-password $admin_password `
    --size Standard_F8s_v2 `
    --vnet-name $vnet_name `
    --subnet $subnet_name `
    --nsg $nsg_name `
    --priority Spot `
    --max-price -1 `
    --public-ip-address-allocation Dynamic `
    --public-ip-sku Basic `
    --eviction-policy Delete


### Test Eviction
az vm simulate-eviction --resource-group $rg_name --name $vm1_name

az vm simulate-eviction --resource-group $rg_name --name $vm2_name


# Notificaciones
# Curl https://curl.se/windows/dl-8.0.1_8/curl-8.0.1_8-win64-mingw.zip
curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-12-13"