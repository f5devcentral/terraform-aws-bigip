locals {
  azs  = [format("%s%s", var.region, "a"), format("%s%s", var.region, "b")]
  cidr = "10.0.0.0/16"
  mgmt_cidrs = flatten([
    for az_num in range(length(local.azs)) : {
      az   = local.azs[az_num]
      cidr = cidrsubnet(var.cidr, 8, az_num)
    }
  ])
  public_cidrs = flatten([
    for az_num in range(length(local.azs)) : [
      for num in range(var.specification[terraform.workspace].number_public_interfaces) : {
        az   = local.azs[az_num]
        cidr = cidrsubnet(var.cidr, 8, 10 + num * 10 + az_num)
      }
    ]
  ])
  private_cidrs = flatten([
    for az_num in range(length(local.azs)) : [
      for num in range(var.specification[terraform.workspace].number_private_interfaces) : {
        az   = local.azs[az_num]
        cidr = cidrsubnet(var.cidr, 8, 20 + num * 10 + az_num)
      }
    ]
  ])
}

#
# Create the VPC
#
resource "aws_vpc" "default" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

#
# Create the management subnets
#
resource "aws_subnet" "mgmt" {
  for_each = {
    for az, cidr in local.mgmt_cidrs : az => cidr
  }

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
}

#
# Create the public subnets
#
resource "aws_subnet" "public" {
  for_each = {
    for az, cidr in local.public_cidrs : az => cidr
  }

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
}

#
# Create the private subnets
#
resource "aws_subnet" "private" {
  for_each = {
    for az, cidr in local.private_cidrs : az => cidr
  }

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
}

#
# Create the internet gateway
#
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id
}

#
# Create the public route table 
#
resource "aws_route_table" "internet-gw" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

#
# Associate the route table to the mgmt subnets
#
resource "aws_route_table_association" "mgmt" {
  for_each = aws_subnet.mgmt

  subnet_id      = each.value.id
  route_table_id = aws_route_table.internet-gw.id
}

#
# Associate the route table to the public subnets
#
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.internet-gw.id
}

#
# Create a security group for BIG-IP
#
module "bigip_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-bigip-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP "
  vpc_id      = aws_vpc.default.id

  ingress_cidr_blocks = [var.allowed_app_cidr]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.bigip_sg.this_security_group_id
    }
  ]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}

#
# Create a security group for BIG-IP Management
#
module "bigip_mgmt_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-bigip-mgmt-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP Management"
  vpc_id      = aws_vpc.default.id

  ingress_cidr_blocks = [var.allowed_mgmt_cidr]
  ingress_rules       = ["https-443-tcp", "https-8443-tcp", "ssh-tcp"]

  ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.bigip_mgmt_sg.this_security_group_id
    }
  ]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}
