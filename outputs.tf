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

output "bigip_map" {
  description = "map of network subnet ids to BIG-IP interface ids and assigned IP addresses"
  value = merge(var.bigip_map, {
    for bigip_id, bigip in aws_instance.f5_bigip : bigip_id => {
      # remove the leading bigip_id on the nic_id so it matches the key in the bigip_map variable
      for nic_id, nic in aws_network_interface.bigip : substr(nic_id, length(tostring(bigip_id)) + 1, length(nic_id)) => nic
      if(tostring(bigip_id) == substr(nic_id, 0, length(tostring(bigip_id))))
    }
  })
}
