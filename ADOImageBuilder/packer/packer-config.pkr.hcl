packer {
  required_plugins {
    azure = {
      version = ">= 2.2.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}