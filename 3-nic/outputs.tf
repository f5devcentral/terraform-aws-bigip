output "mgmt_public_ips" {
  description = "List of BIG-IP public IP addresses for the management interfaces"
  value       = module.bigip.mgmt_public_ips
}

output "mgmt_public_dns" {
  description = "List of BIG-IP public DNS records for the management interfaces"
  value       = module.bigip.mgmt_public_dns
}

output "mgmt_port" {
  description = "HTTPS Port used for the BIG-IP management interface"
  value       = module.bigip.mgmt_port
}

output "public_nic_ids" {
  description = "List of BIG-IP public network interface ids"
  value       = module.bigip.public_nic_ids
}

output "mgmt_addresses" {
  description = "List of BIG-IP management addresses"
  value       = module.bigip.mgmt_addresses
}

output "public_addresses" {
  description = "List of BIG-IP public addresses"
  value       = module.bigip.public_addresses
}

output "private_addresses" {
  description = "List of BIG-IP private addresses"
  value       = module.bigip.private_addresses
}

output "network_subnets" {
  value = module.bigip.network_subnets
}
