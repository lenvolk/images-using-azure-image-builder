# We'll need the following variables:
# Subnet id for Azure Firewall
# VNET id for spoken vnet
# VNET id for hub vnet?

variable "location" {
  type        = string
  description = "(Optional) The Azure region where the resources should be created."
  default     = "eastus2"
}

variable "prefix" {
  type        = string
  description = "(Optional) The prefix for the name of the resources."
  default     = "avd"
}

variable "fw_subnet_id" {
  type        = string
  description = "(Required) Azure Subnet ID for Azure Firewall."
  #default = "/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44/resourceGroups/network-eus/providers/Microsoft.Network/virtualNetworks/mngntVNET/subnets/AzureFirewallSubnet"
}

variable "hub_vnet_resource_group" {
  type        = string
  description = "(Required) The name of the resource group for the Hub VNet."
  #default     = "maintenance"
}
