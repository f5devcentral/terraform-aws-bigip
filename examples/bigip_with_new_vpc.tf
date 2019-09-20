provider "aws" {
  region = local.region
}

# Create the VPC 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = format("%s-vpc", local.prefix)
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

  public_dedicated_network_acl = true
  public_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["public_inbound"]
  )

  private_dedicated_network_acl = true
  private_inbound_acl_rules     = local.network_acls["private_inbound"]

  tags = {
    Name        = format("%s-vpc", local.prefix)
    Terraform   = "true"
    Environment = "dev"
  }
}

locals {
  prefix                 = "terraform-aws-bigip-demo"
  region                 = "us-east-1"
  azs                    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  cidr                   = "10.0.0.0/16"
  public_subnet_numbers  = [1, 2, 3]
  private_subnet_numbers = [11, 12, 13]
  allowed_mgmt_cidr      = "0.0.0.0/0"
  allowed_app_cidr       = "0.0.0.0/0"
  network_acls = {
    default_inbound = [
      {
        # MGMT UI
        rule_number = 900
        from_port   = 443
        to_port     = 443
        rule_action = "allow"
        protocol    = "tcp"
        cidr_block  = local.allowed_mgmt_cidr
      },
      {
        # SSH
        rule_number = 910
        from_port   = 22
        to_port     = 22
        rule_action = "allow"
        protocol    = "tcp"
        cidr_block  = local.allowed_mgmt_cidr
      },
    ]
    public_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = local.allowed_app_cidr
      },
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_block  = local.allowed_app_cidr
      },
    ]
    private_inbound = [
      {
        rule_number = 200
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = "tcp"
        cidr_block  = local.cidr
      }
    ]
  }
}
