# Azure HA Virtual Network - Network Layer

Terraform module that deploys the network layer of a highly available Azure Virtual Network (VNet), spread across 3 Availability Zones (AZs), following a 3-tier subnet design (Public, App, Data), plus a dedicated subnet for Private Endpoints to PaaS services.

## Architecture overview

```
                              Internet
                                 |
                         (Public IP - outbound)
                                 |
                         NAT Gateway (shared)
                                 |
        -------------------------------------------------
        |                        |                        |
   Availability Zone 1     Availability Zone 2     Availability Zone 3
   -------------------     -------------------     -------------------
   Public subnet           Public subnet           Public subnet
   (NSG-Public)            (NSG-Public)            (NSG-Public)
        |                        |                        |
   App subnet               App subnet               App subnet
   (NSG-Private)            (NSG-Private)            (NSG-Private)
        |                        |                        |
   Data subnet              Data subnet              Data subnet
   (NSG-Data)               (NSG-Data)               (NSG-Data)
        -------------------------------------------------
                                 |
                    snet-privatelink (NSG-PrivateLink)
                                 |
                -------------------------------------
                |                |                   |
          Key Vault         Storage Blob       Storage DFS
        (Private Endpoint) (Private Endpoint) (Private Endpoint)
                |                |                   |
              Private DNS Zones (linked to the VNet)
```

## What this deploys

| Resource | Count | Notes |
|---|---|---|
| Resource Group | 1 | Container for all resources |
| Virtual Network | 1 | `10.0.0.0/16` |
| Public subnets | 3 | One per AZ |
| App subnets | 3 | One per AZ |
| Data subnets | 3 | One per AZ |
| Private Endpoints subnet | 1 | Shared across the VNet, not zonal |
| Network Security Groups | 4 | `NSG-Public`, `NSG-Private`, `NSG-Data`, `NSG-PrivateLink` |
| NAT Gateway | 1 | Shared across all 3 AZ public subnets |
| Public IP | 1 | Associated with the NAT Gateway |
| Key Vault | 1 | Public access disabled, reachable only via Private Endpoint |
| Storage Account | 1 | Data Lake Gen2 enabled (HNS), ZRS replication, public access disabled |
| Private Endpoints | 3 | Key Vault (`vault`), Storage Blob (`blob`), Storage DFS (`dfs`) |
| Private DNS Zones | 3 | One per PaaS service, linked to the VNet |

## Design notes

- **Subnets are not zonal in Azure.** Unlike AWS, subnets are logical IP ranges within the VNet and are not tied to a specific AZ. The "one subnet per AZ" structure here mirrors the AWS mental model for IP planning and resource placement (via the `zones` argument on zonal resources).
- **NSGs are reused across AZs.** Since NSGs are policy objects (not zonal resources), a single NSG per tier is associated with all 3 AZ subnets of that tier, avoiding duplicated rule sets.
- **Single shared NAT Gateway.** All 3 public subnets route outbound traffic through one NAT Gateway. This is more cost-effective than one NAT Gateway per AZ, but introduces a cross-zone dependency: if the zone hosting the NAT Gateway fails, the other AZs lose outbound internet access through it. For full zonal resilience, deploy one NAT Gateway per AZ instead (see comments in `nat_gateway.tf`).
- **No explicit "Internet Gateway" object.** In Azure, internet connectivity is a property of a resource's Public IP, not a separate gateway attached to the VNet.
- **Private Endpoints subnet is shared, not per-AZ.** Private Endpoints are not zonal resources, so a single `snet-privatelink` subnet serves all 3 AZs.
- **PaaS services have public access disabled.** Key Vault and the Storage Account are only reachable through their Private Endpoints, over the VNet's private address space - traffic never traverses the public internet or the NAT Gateway.

## NSG protection summary

| NSG | Applies to | Allows | Purpose |
|---|---|---|---|
| `NSG-Public` | Public subnets | HTTP/HTTPS (80/443) from Internet | Entry point filtering |
| `NSG-Private` | App subnets | Traffic from Public subnet CIDRs | App tier isolation |
| `NSG-Data` | Data subnets | Traffic from App subnet CIDRs on DB port (default 5432) | Data tier isolation |
| `NSG-PrivateLink` | Private Endpoints subnet | Traffic from App and Data subnet CIDRs on 443/1433/5432 | Restricts access to PaaS Private Endpoints |

All NSGs deny all other inbound traffic by default (explicit `Deny-All-Inbound` rule at priority 4096).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (logged in via `az login`)
- An active Azure subscription

## Usage

```bash
# Authenticate to Azure (Terraform uses this session automatically)
az login

# Initialize Terraform and download the azurerm provider
terraform init

# Validate configuration
terraform validate

# Review the execution plan
terraform plan

# Apply
terraform apply
```

To destroy all resources:

```bash
terraform destroy
```

## Configuration

Key variables (see `variables.tf` and `variables_privatelink.tf` for the full list and defaults):

| Variable | Default | Description |
|---|---|---|
| `location` | `eastus` | Azure region |
| `resource_group_name` | `rg-ha-vnet` | Resource group name |
| `vnet_name` | `vnet-ha` | VNet name |
| `vnet_address_space` | `["10.0.0.0/16"]` | VNet CIDR |
| `availability_zones` | `["1", "2", "3"]` | AZs to deploy across |
| `public_subnet_cidrs` | `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24` | One per AZ |
| `app_subnet_cidrs` | `10.0.11.0/24`, `10.0.12.0/24`, `10.0.13.0/24` | One per AZ |
| `data_subnet_cidrs` | `10.0.21.0/24`, `10.0.22.0/24`, `10.0.23.0/24` | One per AZ |
| `privatelink_subnet_cidr` | `10.0.30.0/24` | Shared subnet for Private Endpoints |
| `key_vault_name` | `kv-ha-vnet-demo` | Must be globally unique (3-24 alphanumeric chars) |
| `storage_account_name` | `stahavnetdemo` | Must be globally unique (3-24 lowercase alphanumeric chars) |

Override defaults with a `terraform.tfvars` file or `-var` flags:

```bash
terraform apply -var="location=westeurope" -var="resource_group_name=rg-prod-vnet"
```

> **Important:** `key_vault_name` and `storage_account_name` must be globally unique across all of Azure. The defaults are placeholders and will likely fail - set your own values before running `terraform apply`.

## Outputs

| Output | Description |
|---|---|
| `vnet_id` | ID of the created VNet |
| `public_subnet_ids` | IDs of the 3 public subnets |
| `app_subnet_ids` | IDs of the 3 app subnets |
| `data_subnet_ids` | IDs of the 3 data subnets |
| `nat_gateway_id` | ID of the shared NAT Gateway |
| `nat_gateway_public_ip` | Public IP used for outbound traffic |
| `nsg_public_id` / `nsg_private_id` / `nsg_data_id` | NSG IDs |
| `privatelink_subnet_id` | ID of the shared Private Endpoints subnet |
| `key_vault_id` | ID of the Key Vault |
| `key_vault_private_endpoint_ip` | Private IP assigned to the Key Vault Private Endpoint |
| `storage_account_id` | ID of the Storage Account |
| `storage_blob_private_endpoint_ip` | Private IP assigned to the Storage Blob Private Endpoint |
| `storage_dfs_private_endpoint_ip` | Private IP assigned to the Storage DFS (ADLS Gen2) Private Endpoint |

## Cost considerations

This deployment incurs ongoing costs primarily from:

- **NAT Gateway**: hourly charge + data processing charge per GB, regardless of traffic.
- **Public IP (Standard SKU)**: hourly charge.
- **Private Endpoints**: hourly charge per endpoint (3 in this module).
- **Key Vault**: per-operation charges (standard tier).
- **Storage Account**: capacity + transaction charges (ZRS replication has a premium over LRS).

Estimate before deploying using the [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/).

## Next steps

This module covers the network layer and core PaaS connectivity (VNet, subnets, NSGs, NAT Gateway, Private Endpoints to Key Vault and Storage). It does not include:

- Compute resources (VMs, VM Scale Sets, AKS)
- Load balancing (Application Gateway, Azure Load Balancer)
- Relational database services (Azure SQL / PostgreSQL) and their Private Endpoints
- Azure Firewall / centralized policy management
- Additional PaaS Private Endpoints (ACR, Event Hub, Cosmos DB, etc.)

These can be layered on top of this network foundation as separate modules.
