variable "root_id" {
  type    = string
  default = "contoso"
}

variable "root_name" {
  type    = string
  default = "Contoso"
}
variable "managementSubscriptionId" {
  type    = string
  default = "2bc41231-db2a-40c7-95ac-f5507fb57d6f"
}

variable "connectivitySubscriptionId" {
  type    = string
  default = "8f6ac8c1-5438-42b6-9413-90d380174379"
}

variable "identitySubscriptionId" {
  type    = string
  default = "4e2fbda9-52cd-4cb3-ae19-549a494943dc"
}

variable "LandingZoneA1" {
  type    = string
  default = "bf17b12f-576d-457b-a905-656e0e7fb91c"
}

variable "sandboxSubscriptionId" {
  type    = string
  default = "7201ec24-998b-4283-bb78-6bbabc7f3d2d"
}


variable "default_location" {
  type = string
  default = "eastus"
}

variable "primary_location" {
  type = string
  default = "eastus"
}

variable "management_resources_location" {
  type    = string
  default = "eastus"
}

variable "management_resources_tags" {
  type = map(string)
  default = {
    BelongsTo = "management"
	
  }
}

variable "log_retention_in_days" {
  type    = number
  default = 50
}

variable "security_alerts_email_address" {
  type    = string
  default = "pj@contoso.com" 
}


variable "connectivity_resources_location" {
  type    = string
  default = "eastus"
}

variable "connectivity_resources_tags" {
  type = map(string)
  default = {
    BelongsTo = "Connectivity"
  }
}
