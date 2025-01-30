terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.74.0"
    }
  }

  backend "azurerm" {
      resource_group_name  = "tfstate"
      storage_account_name = "tfstatelenvolk24"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
      subscription_id      = "6afc5ee8-735d-463a-b70a-7e652cf2302c"
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "eulz"
  subscription_id = var.LandingZoneA1
  features {}
}


provider "azurerm" {
  alias           = "connectivity"
  subscription_id = var.connectivitySubscriptionId
  features {}
}

provider "azurerm" {
  alias           = "management"
  subscription_id = var.managementSubscriptionId
  features {}
}

provider "azurerm" {
  alias           = "identity"
  subscription_id = var.identitySubscriptionId
  features {}
}

provider "azurerm" {
  alias           = "sandbox"
  subscription_id = var.sandboxSubscriptionId
  features {}
}
