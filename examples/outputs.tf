# # VPC
output "vpc_id" {
  value = aws_vpc.default.id
}

# # BIG-IP Management Public IP Addresses
# output "bigip_mgmt_ips" {
#   value = module.bigip.mgmt_public_ips
# }

# # BIG-IP Management Public DNS Address
# output "bigip_mgmt_dns" {
#   value = module.bigip.mgmt_public_dns
# }

# # BIG-IP Management Port
# output "bigip_mgmt_port" {
#   value = module.bigip.mgmt_port
# }

# # BIG-IP Password
# output "password" {
#   value     = random_password.password
#   sensitive = true
# }

# # BIG-IP Password Secret name
# output "aws_secretmanager_secret_name" {
#   value = aws_secretsmanager_secret.bigip.name
# }

# output "mgmt_addresses" {
#   description = "List of BIG-IP management addresses"
#   value       = module.bigip.mgmt_addresses
# }

# output "public_addresses" {
#   description = "List of BIG-IP public addresses"
#   value       = module.bigip.public_addresses
# }

# output "private_addresses" {
#   description = "List of BIG-IP private addresses"
#   value       = module.bigip.private_addresses
# }

# # Public Network Interface
# output "public_nic_ids" {
#   description = "List of BIG-IP public network interface ids"
#   value       = module.bigip.public_nic_ids
# }

# output "test" {
#   value = local.private_subnet_data
# }
