provider "aws" {
  region = local.region
}

#
# Create a random id
#
resource "random_id" "id" {
  byte_length = 2
}

#
# Create the VPC 
#
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = format("%s-vpc-%s", local.prefix, random_id.id.hex)
  cidr                 = local.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs = local.azs

  public_subnets = [
    for num in range(length(local.azs)) :
    cidrsubnet(local.cidr, 8, num)
  ]

  # using the database subnet method since it allows a public route
  database_subnets = [
    for num in range(length(local.azs)) :
    cidrsubnet(local.cidr, 8, num + 10)
  ]
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  private_subnets = [
    for num in range(length(local.azs)) :
    cidrsubnet(local.cidr, 8, num + 20)
  ]

  tags = {
    Name        = format("%s-vpc-%s", local.prefix, random_id.id.hex)
    Terraform   = "true"
    Environment = "dev"
  }
}

#
# Create a security group for port 80 traffic
#
module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = format("%s-web-server-%s", local.prefix, random_id.id.hex)
  description = "Security group for web-server with HTTP ports"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [local.allowed_app_cidr]
}

#
# Create a security group for port 443 traffic
#
module "web_server_secure_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/https-443"

  name        = format("%s-web-server-secure-%s", local.prefix, random_id.id.hex)
  description = "Security group for web-server with HTTPS ports"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [local.allowed_app_cidr]
}

#
# Create a security group for SSH traffic
#
module "ssh_secure_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"

  name        = format("%s-ssh-%s", local.prefix, random_id.id.hex)
  description = "Security group for SSH ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [local.allowed_mgmt_cidr]
}

#
# Create BIG-IP
#
module bigip {
  source = "../../"

  prefix = format(
    "%s-bigip-1-nic_with_new_vpc-%s",
    local.prefix,
    random_id.id.hex
  )
  f5_instance_count = length(local.azs)
  ec2_key_name      = var.ec2_key_name
  mgmt_subnet_security_group_ids = [
    module.web_server_secure_sg.this_security_group_id,
    module.ssh_secure_sg.this_security_group_id
  ]

  public_subnet_security_group_ids = [
    module.web_server_sg.this_security_group_id,
    module.web_server_secure_sg.this_security_group_id
  ]

  private_subnet_security_group_ids = [
    module.vpc.default_security_group_id
  ]

  vpc_public_subnet_ids  = module.vpc.public_subnets
  vpc_private_subnet_ids = module.vpc.private_subnets
  vpc_mgmt_subnet_ids    = module.vpc.database_subnets
}

#
# Variables used by this example
#
locals {
  prefix            = "tf-aws-bigip"
  region            = "us-east-2"
  azs               = [format("%s%s", local.region, "a"), format("%s%s", local.region, "b")]
  cidr              = "10.0.0.0/16"
  allowed_mgmt_cidr = "0.0.0.0/0"
  allowed_app_cidr  = "0.0.0.0/0"
}
