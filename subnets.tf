# --------------------------------------------------------------------------
# Subnets
# Azure subnets are NOT zonal objects (unlike AWS subnets). They are logical
# IP ranges within the VNet. Zonal placement happens at the RESOURCE level
# (VM, NAT Gateway, Public IP, etc.) via the "zones" argument.
#
# Here we create one subnet per AZ per tier purely to mirror the AWS-style
# "one subnet per AZ" mental model and keep IP planning clean. Resources
# deployed into az1's subnets would typically also be pinned to zone "1".
# --------------------------------------------------------------------------

# Public subnets (one per AZ)
resource "azurerm_subnet" "public" {
  count                = length(var.availability_zones)
  name                 = "snet-public-az${var.availability_zones[count.index]}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.public_subnet_cidrs[count.index]]
}

# App subnets (one per AZ)
resource "azurerm_subnet" "app" {
  count                = length(var.availability_zones)
  name                 = "snet-app-az${var.availability_zones[count.index]}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.app_subnet_cidrs[count.index]]
}

# Data subnets (one per AZ)
resource "azurerm_subnet" "data" {
  count                = length(var.availability_zones)
  name                 = "snet-data-az${var.availability_zones[count.index]}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.data_subnet_cidrs[count.index]]

  # Optional: enable service endpoints for PaaS data services if needed
  # service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
}
