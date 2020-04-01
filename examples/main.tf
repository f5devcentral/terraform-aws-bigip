provider "aws" {
  region = var.region
}

locals {
  azs  = [format("%s%s", var.region, "a"), format("%s%s", var.region, "b")]
  cidr = "10.0.0.0/16"
  mgmt_cidrs = [
    for num in range(length(local.azs)) :
    cidrsubnet(var.cidr, 8, num)
  ]
  mgmt_subnet_data = zipmap(local.azs, local.mgmt_cidrs)
  public_cidrs = [
    for num in range(length(local.azs)) :
    cidrsubnet(var.cidr, 8, num + 10)
  ]
  private_cidrs = [
    for num in range(length(local.azs)) :
    cidrsubnet(var.cidr, 8, num + 20)
    if(var.specification[terraform.workspace].number_private_interfaces > 0 ? true : false)
  ]
  private2_cidrs = [
    for num in range(length(local.azs)) :
    cidrsubnet(var.cidr, 8, num + 30)
    if(var.specification[terraform.workspace].number_private_interfaces > 1 ? true : false)
  ]
  private3_cidrs = [
    for num in range(length(local.azs)) :
    cidrsubnet(var.cidr, 8, num + 40)
    if(var.specification[terraform.workspace].number_private_interfaces > 2 ? true : false)
  ]
  private4_cidrs = [
    for num in range(length(local.azs)) :
    cidrsubnet(var.cidr, 8, num + 50)
    if(var.specification[terraform.workspace].number_private_interfaces > 3 ? true : false)
  ]
  private5_cidrs = [
    for num in range(length(local.azs)) :
    cidrsubnet(var.cidr, 8, num + 60)
    if(var.specification[terraform.workspace].number_private_interfaces > 4 ? true : false)
  ]
  private6_cidrs = [
    for num in range(length(local.azs)) :
    cidrsubnet(var.cidr, 8, num + 70)
    if(var.specification[terraform.workspace].number_private_interfaces > 5 ? true : false)
  ]
  public_subnet_data   = length(local.public_cidrs) > 0 ? zipmap(local.azs, local.public_cidrs) : {}
  private_subnet_data  = length(local.private_cidrs) > 0 ? zipmap(local.azs, local.private_cidrs) : {}
  private2_subnet_data = length(local.private2_cidrs) > 0 ? zipmap(local.azs, local.private2_cidrs) : {}
  private3_subnet_data = length(local.private3_cidrs) > 0 ? zipmap(local.azs, local.private3_cidrs) : {}
  private4_subnet_data = length(local.private4_cidrs) > 0 ? zipmap(local.azs, local.private4_cidrs) : {}
  private5_subnet_data = length(local.private5_cidrs) > 0 ? zipmap(local.azs, local.private5_cidrs) : {}
  private6_subnet_data = length(local.private6_cidrs) > 0 ? zipmap(local.azs, local.private6_cidrs) : {}

  bigip_map = {
    0 = {
      network_interfaces = {
        0 = {
          subnet_id = aws_subnet.mgmt["us-west-1a"].id
          subnet_security_group_ids = [
            module.bigip_mgmt_sg.this_security_group_id
          ]
          interface_type    = "mgmt"
          public_ip         = true
          private_ips_count = 0
        },
        1 = {
          subnet_id = aws_subnet.public["us-west-1a"].id
          subnet_security_group_ids = [
            module.bigip_sg.this_security_group_id
          ]
          interface_type    = "public"
          public_ip         = true
          private_ips_count = 0
        }
        2 = {
          subnet_id = aws_subnet.private["us-west-1a"].id
          subnet_security_group_ids = [
            module.bigip_sg.this_security_group_id
          ]
          interface_type    = "private"
          public_ip         = false
          private_ips_count = 0
        }
        3 = {
          subnet_id = aws_subnet.private2["us-west-1a"].id
          subnet_security_group_ids = [
            module.bigip_sg.this_security_group_id
          ]
          interface_type    = "private"
          public_ip         = false
          private_ips_count = 0
        }
      }
    },
    1 = {
      network_interfaces = {
        0 = {
          subnet_id = aws_subnet.mgmt["us-west-1b"].id
          subnet_security_group_ids = [
            module.bigip_mgmt_sg.this_security_group_id
          ]
          interface_type    = "mgmt"
          public_ip         = true
          private_ips_count = 0
        },
        1 = {
          subnet_id = aws_subnet.public["us-west-1b"].id
          subnet_security_group_ids = [
            module.bigip_sg.this_security_group_id
          ]
          interface_type    = "public"
          public_ip         = true
          private_ips_count = 0
        }
        2 = {
          subnet_id = aws_subnet.private["us-west-1b"].id
          subnet_security_group_ids = [
            module.bigip_sg.this_security_group_id
          ]
          interface_type    = "private"
          public_ip         = false
          private_ips_count = 0
        }
        3 = {
          subnet_id = aws_subnet.private2["us-west-1b"].id
          subnet_security_group_ids = [
            module.bigip_sg.this_security_group_id
          ]
          interface_type    = "private"
          public_ip         = false
          private_ips_count = 0
        }
      }
    }
  }
}

#
# Create a random id
#
resource "random_id" "id" {
  byte_length = 2
}

#
# Create random password for BIG-IP
#
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = " #%*+,-./:=?@[]^_~"
}

#
# Create Secret Store and Store BIG-IP Password
#
resource "aws_secretsmanager_secret" "bigip" {
  name = format("%s-bigip-secret-%s", var.prefix, random_id.id.hex)
}
resource "aws_secretsmanager_secret_version" "bigip-pwd" {
  secret_id     = aws_secretsmanager_secret.bigip.id
  secret_string = random_password.password.result
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
  for_each = local.mgmt_subnet_data

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value
  availability_zone = each.key
}

#
# Create the public subnets
#
resource "aws_subnet" "public" {
  for_each = local.public_subnet_data

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value
  availability_zone = each.key
}

#
# Create the private subnets
#
resource "aws_subnet" "private" {
  for_each = local.private_subnet_data

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value
  availability_zone = each.key
}

#
# Create the private 2 subnets
#
resource "aws_subnet" "private2" {
  for_each = local.private2_subnet_data

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value
  availability_zone = each.key
}

#
# Create the private 3 subnets
#
resource "aws_subnet" "private3" {
  for_each = local.private3_subnet_data

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value
  availability_zone = each.key
}

#
# Create the private 4 subnets
#
resource "aws_subnet" "private4" {
  for_each = local.private4_subnet_data

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value
  availability_zone = each.key
}

#
# Create the private 5 subnets
#
resource "aws_subnet" "private5" {
  for_each = local.private5_subnet_data

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value
  availability_zone = each.key
}

#
# Create the private 6 subnets
#
resource "aws_subnet" "private6" {
  for_each = local.private6_subnet_data

  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value
  availability_zone = each.key
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

#
# Create BIG-IP
#
module bigip {
  source = "../"

  prefix = format(
    "%s-bigip_with_new_vpc-%s",
    var.prefix,
    random_id.id.hex
  )
  ec2_instance_type           = var.specification[terraform.workspace].ec2_instance_type
  ec2_key_name                = var.ec2_key_name
  aws_secretmanager_secret_id = aws_secretsmanager_secret.bigip.id
  bigip_map                   = local.bigip_map
}
