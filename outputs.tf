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

# Public Network Interface
output "public_nic_ids" {
  description = "List of BIG-IP public network interface ids"
  value       = aws_network_interface.public[*].id
}

# BIG-IP EC2 Instance IDs
output "instance_ids" {
  description = "List of BIG-IP EC2 instance ids"
  value       = aws_instance.f5_bigip[*].id
}

# BIG-IP EC2 Instance ARNs
output "instance_arns" {
  description = "List of BIG-IP EC2 instance ARNs"
  value       = aws_instance.f5_bigip[*].arn
}

# BIG-IP IAM Role Name
output "role_name" {
  description = "IAM Role Name attached to the BIG-IP instance profile"
  value       = aws_iam_role.bigip_role.name
}

# BIG-IP Instance Profile ARN
output "instance_profile_arn" {
  description = "IAM Instance Profile ARN attached to the BIG-IP instance"
  value       = aws_iam_instance_profile.bigip_profile.arn
}
