variable "iam_instance_profile" {
    description = ""
}
variable "aws_secretmanager_secret_id" {
    description = "secret id reference for BIG-IP password"
}
variable "ec2_key_name" {
    description = "The name of an AWS EC2 keypair for use when provisioning instances"
}
variable "ec2_instance_type" {
    description = "The AWS EC2 instance type to use when provisioning BIG-IPs"
}
variable "azs" {
    description = "list of availability zones to distribute BIG-IPs"
}
variable "cidr" {
    description = "the CIDR for the VPC"
}
variable "vpcsubnets" {
    description = "map of all subnets in the vpc. subnets must be tagged with subnet_type and bigip_device_index."
}
variable "management_security_groups" {
    description = "list of security groups for management nics"
}
variable "public_security_groups" {
    description = "list of security groups for public nics"
    default = []
}
variable "private_security_groups" {
    description = "list of security groups for private nics"
    default = []
}
variable "prefix" {
    description = ""
}