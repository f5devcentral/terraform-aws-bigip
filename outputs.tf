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

output "all_nic_ids_extended" {
  description = "Extended list of BIG-IP network interfaces"
  value =  flatten([   for bigip, bigip_data in var.bigip_map : [
      for id, network_interface in bigip_data.network_interfaces : {
        bigip             = bigip
        id                = id
        eni               = aws_network_interface.bigip[format("%s.%s",bigip,id)].id
        subnet_id         = network_interface.subnet_id
        security_groups   = network_interface.subnet_security_group_ids
        interface_type    = network_interface.interface_type
        public_ip         = network_interface.public_ip
        private_ips_count = network_interface.private_ips_count
        device_index      = network_interface.device_index
        cloudfailover_tag = network_interface.cloudfailover_tag
      }
    ]
  ])
}

output "nics_by_device_index" {
  description = "map of nic ids indexed by device index"
  value =  {   
    for bigip, bigip_data in var.bigip_map : bigip => {
      for nicid, nicdata in bigip_data.network_interfaces :
        nicdata.device_index => {
          eni               = aws_network_interface.bigip[format("%s.%s",bigip,nicid)].id
          subnet_id         = nicdata.subnet_id
          security_groups   = nicdata.subnet_security_group_ids
          interface_type    = nicdata.interface_type
          public_ip         = nicdata.public_ip
          private_ips_count = nicdata.private_ips_count
          device_index      = nicdata.device_index
          cloudfailover_tag = nicdata.cloudfailover_tag
        }
    } 
  }
}