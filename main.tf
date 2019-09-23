# Find BIG-IP AMI
data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["${var.f5_ami_search_name}"]
  }
}

# Create random password for BIG-IP
resource "random_string" "password" {
  length           = 16
  special          = true
  override_special = "@"
}

# Deploy BIG-IP
resource "aws_instance" "f5_bigip" {
  count         = var.f5_instance_count
  instance_type = var.ec2_instance_type
  ami           = data.aws_ami.f5_ami.id

  key_name                    = var.ec2_key_name
  vpc_security_group_ids      = var.vpc_security_group_ids
  subnet_id                   = element(var.vpc_mgmt_subnet_ids, count.index)
  associate_public_ip_address = var.mgmt_eip

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = format("%s-%d", var.prefix, count.index)
  }
}
