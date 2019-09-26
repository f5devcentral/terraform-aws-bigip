# VPC
output "vpc_id" {
  value = module.vpc.vpc_id
}

# BIG-IP Management Public IP Addresses
output "bigip_mgmt_ips" {
  value = module.bigip.mgmt_public_ips
}

# BIG-IP Management Public DNS Address
output "bigip_mgmt_dns" {
  value = module.bigip.mgmt_public_dns
}

# BIG-IP Management Port
output "bigip_mgmt_port" {
  value = module.bigip.mgmt_port
}
# BIG-IP Password
output "password" {
  value = module.bigip.password
}
