locals {
  azs  = [format("%s%s", var.region, "a"), format("%s%s", var.region, "b")]
  cidr = "10.0.0.0/16"
}

#
# Create the VPC
#
resource "aws_vpc" "default" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}
resource "aws_subnet" "management" {
  count = length(var.azs)
  vpc_id            = aws_vpc.default.id
  cidr_block        = cidrsubnet(var.cidr, 8, count.index)
  availability_zone = var.azs[count.index]
  tags = {
    subnet_type        = "management"
    bigip_device_index = 0
  }  
}
resource "aws_subnet" "public" {
  count = length(var.azs)
  vpc_id            = aws_vpc.default.id
  cidr_block        =  cidrsubnet(var.cidr, 8, 10 + count.index)
  availability_zone = var.azs[count.index]
  tags = {
    subnet_type        = "public"
    bigip_device_index = 1
  }  
}
resource "aws_subnet" "private" {
  count = length(var.azs)
  vpc_id            = aws_vpc.default.id
  cidr_block        =  cidrsubnet(var.cidr, 8, 20 + count.index)
  availability_zone = var.azs[count.index]
  tags = {
    subnet_type        = "private"
    bigip_device_index = 2
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
resource "aws_route_table_association" "management" {
  count = length(var.azs)

  subnet_id      = aws_subnet.management[count.index].id
  route_table_id = aws_route_table.internet-gw.id
}
resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
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
