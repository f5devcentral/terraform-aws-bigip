locals {
  azs  = [format("%s%s", var.region, "a"), format("%s%s", var.region, "b")]
  cidr = "10.0.0.0/16"
  management_interface_count = 1
  public_interface_count = var.specification[terraform.workspace].number_public_interfaces
  private_interface_count = var.specification[terraform.workspace].number_private_interfaces
  mgmt_cidrs = flatten([
    for az_num in range(length(local.azs)) : {
      num          = 0 # fixed to zero because there's only 
      device_index = 0
      az           = local.azs[az_num]
      cidr         = cidrsubnet(var.cidr, 8, az_num)
      subnet_type  = "management"
    }
  ])
  public_cidrs = flatten([
    for az_num in range(length(local.azs)) : [
      for num in range(local.public_interface_count) : {
        num          = num
        device_index = local.management_interface_count + num
        az           = local.azs[az_num]
        cidr         = cidrsubnet(var.cidr, 8, 10 + num * 10 + az_num)
        subnet_type  = "public"
      }
    ]
  ])
  private_cidrs = flatten([
    for az_num in range(length(local.azs)) : [
      for num in range(local.private_interface_count) : {
        num          = num
        device_index = local.management_interface_count + local.public_interface_count + num
        az           = local.azs[az_num]
        cidr         = cidrsubnet(var.cidr, 8, 20 + num * 10 + az_num)
        subnet_type  = "private"
      }
    ]
  ])
  all_cidrs = concat(local.mgmt_cidrs,local.public_cidrs,local.private_cidrs)

  # map security groups to the type of interface
  # they should be used with
  interface_security_groups = {
    "management" = [module.bigip_mgmt_sg.this_security_group_id]
    "public" = [module.bigip_sg.this_security_group_id]
    "private" = [module.bigip_sg.this_security_group_id]
  }

  bigip_map = {
    for num in range(length(local.azs)): num => {
        network_interfaces = {
          for subnet_key, subnet in aws_subnet.vpcsubnets:
          subnet_key => {
            subnet_id                 = subnet.id
            subnet_security_group_ids = lookup(local.interface_security_groups,subnet.tags.subnet_type,[])
            interface_type            = subnet.tags.subnet_type
            public_ip                 = (subnet.tags.subnet_type == "management" || subnet.tags.subnet_type == "public") ? true : false
            private_ips_count         = 0
            device_index              = subnet.tags.bigip_device_index
            cloudfailover_tag         = var.cloudfailover_tag
          }
          if subnet.availability_zone == local.azs[num]
        }
    }
  }

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
    subnet_type        = each.value.subnet_type
    bigip_device_index = each.value.device_index
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
