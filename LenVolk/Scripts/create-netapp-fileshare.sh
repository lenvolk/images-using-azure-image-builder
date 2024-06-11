# We are going to use the portal to provision the NetApp Files account and file share
# In case you wanted to use the CLI, here are the commands

# Log into Azure
az login
az account set -s "Your_Subscription_Name"

location="LOCATION"

# Create a resource group
az group create --name "avd-netapp" --location $location

# Register the netapp provider
az provider register --namespace Microsoft.NetApp --wait

# 01 Create the NetApp Files account
az netappfiles account create --resource-group "avd-netapp" \
  --location $location --account-name "avdnetapp"

# 02 Create the NetApp Files pool
# Premium is recommended for production
az netappfiles pool create --resource-group "avd-netapp" \
  --location $location --account-name "avdnetapp" \
  --pool-name "avdpool" --service-level "Standard" --size 2

# 03 Create an Active Directory connection (computer object is not yet created in AD, only after volume creation it will show up)
# https://learn.microsoft.com/en-us/azure/azure-netapp-files/create-active-directory-connections
aduser="AD_USER" # username only, no domain component
adpass='AD_PASSWORD'
dcipaddress="DC_IP_ADDR" # IPv4 address of the domain controller
domainname="DOMAIN_NAME" # e.g. contoso.com
site="SITE_NAME" # e.g. Default-First-Site-Name
oupath="OU_PATH" # No DC component, e.g. OU=NetApp

# SMB Server Name Prefix: For example, if the naming standard that your organization uses for file services is NAS-01, NAS-02, and so on, then you would use NAS for the prefix

az netappfiles account ad add -g "avd-netapp" \
  --name "avdnetapp" --username $aduser \
  --password $adpass --smb-server-name ANF \
  --dns $dcipaddress --domain $domainname \
  --site $site --organizational-unit $oupath

# Create the NetApp Files volume
vnetID="VNET_ID" # Resource ID of the VNET
subnetName="SUBNET_NAME" # Name of the subnet !!! Make sure it is deligated to the NetApp Files service
az netappfiles volume create -g "avd-netapp" \
  --account-name "avdnetapp" --pool-name "avdpool" \
  --name "avd-vol01" -l $location \
  --service-level "Standard" --usage-threshold 100 \
  --file-path "avd-vol01" --vnet $vnetID \
  --subnet $subnetName --protocol-types CIFS \
  --network-features "Standard"
