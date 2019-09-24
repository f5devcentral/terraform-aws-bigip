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

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = file(var.ec2_private_key)
    host        = self.public_ip
  }
  provisioner "local-exec" {
    command = "ssh -i ${var.ec2_private_key} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=20 -v admin@${self.public_dns} 'modify auth user admin password \"${random_string.password.result}\"'"
  }

  # enable bash in order to use Terraform primitives
  provisioner "local-exec" {
    command = "ssh -i ${var.ec2_private_key} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=10 -v admin@${self.public_dns} 'modify auth user admin shell bash'"
  }

  #
  # download and install AS3 and Declarative Onboarding
  #
  provisioner "file" {
    content       = "${data.template_file.vm_onboard.rendered}"
    destination   = "/var/tmp/onboard.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /var/tmp/onboard.sh",
      "/var/tmp/onboard.sh"
    ]
  }


}

data "template_file" "vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname        	              = "admin"
    upassword        	          = "${random_string.password.result}"
    DO_onboard_URL              = "${var.DO_onboard_URL}"
    AS3_URL		                  = "${var.AS3_URL}"
    libs_dir		                = "${var.libs_dir}"
    onboard_log		              = "${var.onboard_log}"
    management_interface_delay  = "${var.waitformgmtintf}"
  }
}
