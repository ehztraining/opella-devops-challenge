output "vnet_id" {
  description = "The ID of the created Virtual Network."
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the created Virtual Network."
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_location" {
  description = "The location of the created Virtual Network."
  value       = azurerm_virtual_network.vnet.location
}

output "subnet_ids" {
  description = "A map of subnet names to their IDs."
  value       = { for k, v in azurerm_subnet.subnet : k => v.id }
}

output "subnets" {
  description = "A map of subnet names to their full subnet objects."
  value       = azurerm_subnet.subnet
}

output "nsg_id" {
  description = "The ID of the created Network Security Group."
  value       = azurerm_network_security_group.nsg.id
}

output "nsg_name" {
  description = "The Name of the created Network Security Group."
  value       = azurerm_network_security_group.nsg.name
} 