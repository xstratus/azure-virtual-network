output "vnet_id" {
  description = "ID of the created Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, one per AZ"
  value       = azurerm_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "IDs of the app subnets, one per AZ"
  value       = azurerm_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "IDs of the data subnets, one per AZ"
  value       = azurerm_subnet.data[*].id
}

output "nat_gateway_id" {
  description = "ID of the shared NAT Gateway"
  value       = azurerm_nat_gateway.this.id
}

output "nat_gateway_public_ip" {
  description = "Public IP address used by the NAT Gateway for outbound traffic"
  value       = azurerm_public_ip.nat.ip_address
}

output "nsg_public_id" {
  description = "ID of the NSG applied to public subnets"
  value       = azurerm_network_security_group.public.id
}

output "nsg_private_id" {
  description = "ID of the NSG applied to app subnets"
  value       = azurerm_network_security_group.private.id
}

output "nsg_data_id" {
  description = "ID of the NSG applied to data subnets"
  value       = azurerm_network_security_group.data.id
}

output "privatelink_subnet_id" {
  description = "ID of the shared Private Endpoints subnet"
  value       = azurerm_subnet.privatelink.id
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "key_vault_private_endpoint_ip" {
  description = "Private IP address assigned to the Key Vault Private Endpoint"
  value       = azurerm_private_endpoint.key_vault.private_service_connection[0].private_ip_address
}

output "storage_account_id" {
  description = "ID of the Storage Account"
  value       = azurerm_storage_account.this.id
}

output "storage_blob_private_endpoint_ip" {
  description = "Private IP address assigned to the Storage Account Blob Private Endpoint"
  value       = azurerm_private_endpoint.storage_blob.private_service_connection[0].private_ip_address
}

output "storage_dfs_private_endpoint_ip" {
  description = "Private IP address assigned to the Storage Account DFS (ADLS Gen2) Private Endpoint"
  value       = azurerm_private_endpoint.storage_dfs.private_service_connection[0].private_ip_address
}
