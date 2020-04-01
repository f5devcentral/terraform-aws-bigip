locals {
  azs  = [format("%s%s", var.region, "a"), format("%s%s", var.region, "b")]
  cidr = "10.0.0.0/16"
  mgmt_cidrs = flatten([
    for az_num in range(length(local.azs)) : {
      num         = 0 # fixed to zero because there's only 
      az          = local.azs[az_num]
      cidr        = cidrsubnet(var.cidr, 8, az_num)
      subnet_type = "management"
    }
  ])
  public_cidrs = flatten([
    for az_num in range(length(local.azs)) : [
      for num in range(var.specification[terraform.workspace].number_public_interfaces) : {
        num         = num
        az          = local.azs[az_num]
        cidr        = cidrsubnet(var.cidr, 8, 10 + num * 10 + az_num)
        subnet_type = "public"
      }
    ]
  ])
  private_cidrs = flatten([
    for az_num in range(length(local.azs)) : [
      for num in range(var.specification[terraform.workspace].number_private_interfaces) : {
        num         = num
        az          = local.azs[az_num]
        cidr        = cidrsubnet(var.cidr, 8, 20 + num * 10 + az_num)
        subnet_type = "private"
      }
    ]
  ])
  all_cidrs = concat(local.mgmt_cidrs,local.public_cidrs,local.private_cidrs)
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
# create all of the subnets
# subnets will be keyed by availability zone, subnet purpose, and an index value
# for example, "us-west-2a:management:0" or "us-west-2b:private:1"
#
resource "aws_subnet" "vpcsubnets" {
  for_each = {
    for id, subnetdata in local.all_cidrs : 
      "${subnetdata.az}:${subnetdata.subnet_type}:${subnetdata.num}" => subnetdata
  }
  vpc_id            = aws_vpc.default.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = {
    subnet_type = each.value.subnet_type
  }
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
# Associate the route table to the management and public subnets
#
resource "aws_route_table_association" "routetables" {
  for_each = {
      for id, subnet in aws_subnet.vpcsubnets:
      id => subnet
      if (subnet.tags.subnet_type == "management" || subnet.tags.subnet_type == "public")
  }

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
