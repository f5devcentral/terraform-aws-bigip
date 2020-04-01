output "mgmt_public_ips" {
  description = "List of BIG-IP public IP addresses for the management interfaces"
  value = [
    for id, nic in local.mgmt_network_interfaces :
    aws_eip.bigip[id].public_ip
  ]
}

output "mgmt_public_dns" {
  description = "List of BIG-IP public DNS records for the management interfaces"
  value = [
    for id, nic in local.mgmt_network_interfaces :
    aws_eip.bigip[id].public_dns
  ]
}

output "mgmt_port" {
  description = "HTTPS Port used for the BIG-IP management interface"
  value       = coalesce(local.public_addresses, local.private_addresses) == [] ? "8443" : "443"
}

output "public_nic_ids" {
  description = "List of BIG-IP public network interface ids"
  value = [
    for id, nic in local.public_network_interfaces :
    aws_network_interface.bigip[id].id
  ]
}

output "mgmt_addresses" {
  description = "List of BIG-IP management addresses"
  value = [
    for id, nic in local.mgmt_network_interfaces :
    aws_eip.bigip[id].private_ip
  ]
}

output "public_addresses" {
  description = "List of BIG-IP public addresses"
  value       = local.public_addresses
}

output "private_addresses" {
  description = "List of BIG-IP private addresses"
  value       = local.private_addresses
}

output "network_subnets" {
  value = local.network_subnets
}
