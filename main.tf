provider "aws" {
  region = var.region
}

# Create the VPC 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = format("%s-vpc", var.prefix)
  create_vpc           = var.create_vpc
  cidr                 = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs = var.azs
  private_subnets = [
    for num in var.private_subnet_numbers :
    cidrsubnet(var.cidr, 8, num)
  ]
  public_subnets = [
    for num in var.public_subnet_numbers :
    cidrsubnet(var.cidr, 8, num)
  ]

  public_dedicated_network_acl = true
  public_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["public_inbound"]
  )

  tags = {
    Name        = format("%s-vpc", var.prefix)
    Terraform   = "true"
    Environment = "dev"
  }
}

locals {
  network_acls = {
    default_inbound = [
      {
        # MGMT UI
        rule_number = 900
        from_port   = 443
        to_port     = 443
        rule_action = "allow"
        protocol    = "tcp"
        cidr_block  = var.allowed_mgmt_cidr
      },
      {
        # SSH
        rule_number = 910
        from_port   = 22
        to_port     = 22
        rule_action = "allow"
        protocol    = "tcp"
        cidr_block  = var.allowed_mgmt_cidr
      },
    ]
    public_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = var.allowed_app_cidr
      },
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_block  = var.allowed_app_cidr
      },
    ]
  }
}
