# BIG-IP Management Public IP Addresses
output "mgmt_public_ips" {
  description = "List of BIG-IP public IP addresses for the management interfaces"
  value       = aws_eip.mgmt[*].public_ip
}

# BIG-IP Management Public DNS
output "mgmt_public_dns" {
  description = "List of BIG-IP public DNS records for the management interfaces"
  value       = aws_eip.mgmt[*].public_dns
}

# BIG-IP Management Port
output "mgmt_port" {
  description = "HTTPS Port used for the BIG-IP management interface"
  value       = length(var.vpc_public_subnet_ids) > 0 ? "443" : "8443"
}

# BIG-IP Password
output "password" {
  description = "BIG-IP password stored in AWS Secrets Manager"
  value       = random_string.password.result
  sensitive   = true
}
# Public Network Interface
output "public_nic_ids" {
  description = "List of BIG-IP public network interface ids"
  value       = aws_network_interface.public[*].id
}
