# --------------------------------------------------------------------------
# Container Apps subnet
#
# Dedicated + delegated to Microsoft.App/environments, required for a
# workload-profiles Container Apps Environment with custom VNet integration.
# Sized /23 (min supported is /27, but Container Apps reserves a chunk of
# the range for infra and this leaves room to grow, consistent with the
# other tiers in this VNet).
#
# The environment consuming this subnet (in azure-container-apps-poc) is
# INTERNAL-only (internal_load_balancer_enabled = true) - Application
# Gateway is the only public entry point, terminating TLS and forwarding to
# the Container App over the VNet. This also means NSG rules here actually
# apply (Microsoft docs: for an *external* workload-profile environment,
# inbound traffic bypasses the subnet's NSG via a Microsoft-managed public
# IP - internal-only is what makes this subnet's NSG meaningful).
# --------------------------------------------------------------------------

resource "azurerm_subnet" "containerapps" {
  name                 = "snet-containerapps"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.containerapps_subnet_cidr]

  delegation {
    name = "containerapps-delegation"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# NSG-ContainerApps: only allows the Application Gateway subnet in on the
# Container Apps edge proxy ports, plus the platform's own health probes and
# internal infra chatter. Outbound isn't restricted here (same convention as
# the other tiers) - Container Apps needs outbound to several Azure service
# tags (ACR, AAD, Monitor, Azure DNS) that the default outbound-allow rules
# already cover.
resource "azurerm_network_security_group" "containerapps" {
  name                = "nsg-containerapps"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Application Gateway -> Container Apps internal edge proxy. 80/443 are
  # the "normal" ports; 31080/31443 are where the environment's edge proxy
  # actually answers behind the internal load balancer.
  security_rule {
    name                       = "Allow-AppGateway-To-Edge-Proxy"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "31080", "31443"]
    source_address_prefix      = var.appgw_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-VNet-Inbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "containerapps" {
  subnet_id                 = azurerm_subnet.containerapps.id
  network_security_group_id = azurerm_network_security_group.containerapps.id
}

# rt-containerapps: no 0.0.0.0/0 entry - outbound Internet access (needed for
# ACR image pulls, AAD, Azure Monitor) is provided via direct NAT Gateway
# association, same pattern as rt-app and rt-aks.
resource "azurerm_route_table" "containerapps" {
  name                          = "rt-containerapps"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  bgp_route_propagation_enabled = true
  tags                          = local.tags
}

resource "azurerm_subnet_route_table_association" "containerapps" {
  subnet_id      = azurerm_subnet.containerapps.id
  route_table_id = azurerm_route_table.containerapps.id
}

resource "azurerm_subnet_nat_gateway_association" "containerapps" {
  subnet_id      = azurerm_subnet.containerapps.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}
