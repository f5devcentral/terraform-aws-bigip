# BIG-IP Management Public IP Addresses
output "mgmt_public_ips" {
  value = aws_eip.mgmt[*].public_ip
}

# BIG-IP Management Public DNS
output "mgmt_public_dns" {
  value = aws_eip.mgmt[*].public_dns
}

# BIG-IP Management Port
output "mgmt_port" {
  value = length(var.vpc_public_subnet_ids) > 0 ? "443" : "8443"
}

# BIG-IP Password
output "password" {
  value = random_string.password.result
}
# Public Network Interface
output "public_nic_ids" {
  value = aws_network_interface.public[*].id
}
