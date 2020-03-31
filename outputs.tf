output "mgmt_public_ips" {
  description = "List of BIG-IP public IP addresses for the management interfaces"
  value       = local.mgmt_eips_public_ip
}

output "mgmt_public_dns" {
  description = "List of BIG-IP public DNS records for the management interfaces"
  value       = local.mgmt_eips_public_dns
}

output "mgmt_port" {
  description = "HTTPS Port used for the BIG-IP management interface"
  value       = local.mgmt_port
}

output "public_nic_ids" {
  description = "List of BIG-IP public network interface ids"
  value       = local.public_network_interface_ids
}

output "mgmt_addresses" {
  description = "List of BIG-IP management addresses"
  value       = local.mgmt_ips
}

output "public_addresses" {
  description = "List of BIG-IP public addresses"
  value       = local.public_ips
}

output "private_addresses" {
  description = "List of BIG-IP private addresses"
  value       = local.private_ips
}

output "network_subnets" {
  value = local.network_subnets
}
