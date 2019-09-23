provider "aws" {
  region = local.region
}

# Create a random id
resource "random_id" "id" {
  byte_length = 2
}

# Create the VPC 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = format("%s-vpc-%s", local.prefix, random_id.id.hex)
  cidr                 = local.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs = local.azs
  private_subnets = [
    for num in local.private_subnet_numbers :
    cidrsubnet(local.cidr, 8, num)
  ]
  public_subnets = [
    for num in local.public_subnet_numbers :
    cidrsubnet(local.cidr, 8, num)
  ]

  tags = {
    Name        = format("%s-vpc-%s", local.prefix, random_id.id.hex)
    Terraform   = "true"
    Environment = "dev"
  }
}

module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = format("%s-web-server-%s", local.prefix, random_id.id.hex)
  description = "Security group for web-server with HTTP ports"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "web_server_secure_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/https-443"

  name        = format("%s-web-server-secure-%s", local.prefix, random_id.id.hex)
  description = "Security group for web-server with HTTPS ports"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "bigip_mgmt_secure_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/https-8443"

  name        = format("%s-bigip-mgmt-%s", local.prefix, random_id.id.hex)
  description = "Security group for BIG-IP MGMT Interface"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "ssh_secure_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"

  name        = format("%s-ssh-%s", local.prefix, random_id.id.hex)
  description = "Security group for SSH ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

# Create BIG-IP
module bigip {
  source = "../../"

  prefix       = format("%s-3-nic_with_new_vpc-%s", local.prefix, random_id.id.hex)
  ec2_key_name = "cody-key"
  vpc_security_group_ids = [
    module.web_server_sg.this_security_group_id,
    module.web_server_secure_sg.this_security_group_id,
    module.ssh_secure_sg.this_security_group_id,
    module.bigip_mgmt_secure_sg.this_security_group_id
  ]
  vpc_public_subnet_ids  = []
  vpc_private_subnet_ids = []
  vpc_mgmt_subnet_ids    = [module.vpc.public_subnets[0]]
}

locals {
  prefix                 = "tf-aws-bigip"
  region                 = "us-east-1"
  azs                    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  cidr                   = "10.0.0.0/16"
  public_subnet_numbers  = [1]
  private_subnet_numbers = []
  allowed_mgmt_cidr      = "0.0.0.0/0"
  allowed_app_cidr       = "0.0.0.0/0"
}
