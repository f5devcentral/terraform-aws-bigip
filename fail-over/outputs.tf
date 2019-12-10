# BIG-IP Management Public IP Addresses
output "mgmt_public_ips" {
  description = "List of BIG-IP public IP addresses for the management interfaces"
  value       = module.bigip.mgmt_public_ips
}

# BIG-IP Management Public DNS
output "mgmt_public_dns" {
  description = "List of BIG-IP public DNS records for the management interfaces"
  value       = module.bigip.mgmt_public_dns
}

# BIG-IP Management Port
output "mgmt_port" {
  description = "HTTPS Port used for the BIG-IP management interface"
  value       = module.bigip.mgmt_port
}

# Public Network Interface
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

output "application_public_ips"{
  value = aws_eip.application_eips[*].public_ip
}

output "failover_declaration" {
    value = templatefile(
        "${path.module}/failover_declaration.json",
        {
            failover_scope = var.failover_scope,
            failover_label = join(",\n ",[
            for apptag in local.failover_tags:
            "'f5_cloud_failover_label': '${apptag["f5_cloud_failover_label"]}'"
            ]),
        }
        )
}