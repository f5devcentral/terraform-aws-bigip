#
# Find BIG-IP AMI
#
data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["${var.f5_ami_search_name}"]
  }
}

#
# Create random password for BIG-IP
#
resource "random_string" "password" {
  length           = 16
  special          = true
  override_special = "@"
}

# 
# Create Public Netowrk Interfaces
#
resource "aws_network_interface" "public" {
  count     = length(var.vpc_public_subnet_ids)
  subnet_id = var.vpc_public_subnet_ids[count.index]
}

# 
# Create Private Netowrk Interfaces
#
resource "aws_network_interface" "private" {
  count     = length(var.vpc_private_subnet_ids)
  subnet_id = var.vpc_private_subnet_ids[count.index]
}

#
# Deploy BIG-IP
#
resource "aws_instance" "f5_bigip" {
  # determine the number of BIG-IPs to deploy
  count         = var.f5_instance_count
  instance_type = var.ec2_instance_type
  ami           = data.aws_ami.f5_ami.id

  key_name               = var.ec2_key_name
  vpc_security_group_ids = var.vpc_security_group_ids

  # there should be a unique subnet for each targeted BIG-IP
  # so var.f5_instance_count == length(var.vpc_mgmt_subnet_ids)
  subnet_id = element(var.vpc_mgmt_subnet_ids, count.index)

  # boolean expression to determine if an EIP should be added
  # to the BIG-IP management interface
  associate_public_ip_address = var.mgmt_eip

  root_block_device {
    delete_on_termination = true
  }

  dynamic "network_interface" {
    for_each = aws_network_interface.public[0]

    content {
      network_interface_id = network_interface.id
      device_index         = 1
    }
  }

  tags = {
    Name = format("%s-%d", var.prefix, count.index)
  }

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  #
  # set the BIG-IP password
  #
  provisioner "local-exec" {
    command = "ssh -i ${var.private_key_path} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=20 admin@${self.public_dns} 'modify auth user admin password \"${random_string.password.result}\"'"
  }

  #
  # enable bash in order to use Terraform primitives
  #
  provisioner "local-exec" {
    command = "ssh -i ${var.private_key_path} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=10 admin@${self.public_dns} 'modify auth user admin shell bash'"
  }

  #
  # download and install AS3 and Declarative Onboarding
  #
  provisioner "file" {
    content     = "${data.template_file.vm_onboard.rendered}"
    destination = "/var/tmp/onboard.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /var/tmp/onboard.sh",
      "/var/tmp/onboard.sh"
    ]
  }
}

# 
# build the DO declaration
# 
data "template_file" "vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname                      = "admin"
    upassword                  = "${random_string.password.result}"
    DO_onboard_URL             = "${var.DO_onboard_URL}"
    AS3_URL                    = "${var.AS3_URL}"
    libs_dir                   = "${var.libs_dir}"
    onboard_log                = "${var.onboard_log}"
    management_interface_delay = "${var.waitformgmtintf}"
  }
}
