variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-ha-vnet"
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "vnet-ha"
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "availability_zones" {
  description = "Availability zones to deploy resources across"
  type        = list(string)
  default     = ["1", "2", "3"]
}

# Subnet CIDR blocks per AZ
# AZ1 -> index 0, AZ2 -> index 1, AZ3 -> index 2
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for app subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "data_subnet_cidrs" {
  description = "CIDR blocks for data subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    environment = "production"
    project     = "ha-vnet"
    managed_by  = "terraform"
  }
}
