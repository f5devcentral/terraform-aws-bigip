variable "iam_instance_profile" {
    description = ""
}
variable "aws_secretmanager_secret_id" {
    description = ""
}
variable "ec2_key_name" {
    description = ""
}
variable "ec2_instance_type" {
    description = ""
}
variable "azs" {
    description = "list of availability zones"
}
variable "cidr" {
    description = ""
}
variable "vpcsubnets" {
    description = "map of all subnets in the vpc. subnets must be tagged with subnet_type and bigip_device_index."
}
variable "management_security_groups" {
    description = "list of security groups for management nics"
}
variable "public_security_groups" {
    description = "list of security groups for public nics"
}
variable "private_security_groups" {
    description = "list of security groups for private nics"
}
variable "prefix" {
    description = ""
}