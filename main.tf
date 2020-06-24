#
# Set local values
#
locals {
  network_subnets = flatten([
    for bigip, bigip_data in var.bigip_map : [
      for id, network_interface in bigip_data.network_interfaces : {
        bigip             = bigip
        id                = id
        subnet_id         = network_interface.subnet_id
        security_groups   = network_interface.subnet_security_group_ids
        interface_type    = network_interface.interface_type
        public_ip         = network_interface.public_ip
        private_ips_count = network_interface.private_ips_count
        device_index      = network_interface.device_index
        cloudfailover_tag = network_interface.cloudfailover_tag
      }
    ]
  ])

  mgmt_network_interfaces = {
    for nic in local.network_subnets :
    "${nic.bigip}.${nic.id}" => nic
    if(nic.interface_type == "management" ? true : false)
  }

  public_network_interfaces = {
    for nic in local.network_subnets :
    "${nic.bigip}.${nic.id}" => nic
    if(nic.interface_type == "public" ? true : false)
  }

  all_network_interfaces = {
    for nic in local.network_subnets :
    "${nic.bigip}.${nic.id}" => nic
  }

  private_network_interfaces = {
    for nic in local.network_subnets :
    "${nic.bigip}.${nic.id}" => nic
    if(nic.interface_type == "private" ? true : false)
  }

  public_addresses = [
    for id, nic in local.public_network_interfaces :
    aws_network_interface.bigip[id].private_ip
  ]

  private_addresses = [
    for id, nic in local.private_network_interfaces :
    aws_network_interface.bigip[id].private_ip
  ]
}

#
# Ensure Secret exists
#
data "aws_secretsmanager_secret" "password" {
  name = var.aws_secretmanager_secret_id
}

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
# Create Network Interfaces
#
resource "aws_network_interface" "bigip" {
  for_each = {
    for nic in local.network_subnets :
    "${nic.bigip}.${nic.id}" => nic
  }
  subnet_id         = each.value.subnet_id
  security_groups   = each.value.security_groups
  private_ips_count = each.value.private_ips_count
  source_dest_check = (each.value.interface_type == "management")
  tags = {
    "bigip_interface_type" : each.value.interface_type,
    "bigip_public_ip" : each.value.public_ip
    "f5_cloud_failover_label" : each.value.cloudfailover_tag
  }
}

#
# add an elastic IP to the BIG-IP interfaces that require one
#
resource "aws_eip" "bigip" {
  for_each = {
    for nic in local.network_subnets :
    "${nic.bigip}.${nic.id}" => nic
    if nic.public_ip
  }
  network_interface = aws_network_interface.bigip["${each.value.bigip}.${each.value.id}"].id
  vpc               = true
}



#
#Deploy BIG-IP
#
resource "aws_instance" "f5_bigip" {
  # determine the number of BIG-IPs to deploy
  count                = length(var.bigip_map)
  instance_type        = var.ec2_instance_type
  ami                  = data.aws_ami.f5_ami.id
  iam_instance_profile = var.iam_instance_profile

  key_name = var.ec2_key_name

  root_block_device {
    delete_on_termination = true
  }

  # set the network interfaces
  dynamic "network_interface" {
    for_each = {
      for nic in local.network_subnets :
      "${nic.bigip}.${nic.id}" => nic
      if tonumber(nic.bigip) == count.index
    }

    content {
      network_interface_id = aws_network_interface.bigip["${network_interface.value.bigip}.${network_interface.value.id}"].id
      device_index         = network_interface.value.device_index
    }
  }

  # build user_data file from template
  user_data = var.custom_user_data != null ? var.custom_user_data : templatefile(
    "${path.module}/f5_onboard.tmpl",
    {
      DO_URL      = var.DO_URL,
      AS3_URL     = var.AS3_URL,
      TS_URL      = var.TS_URL,
      CFE_URL     = var.CFE_URL,
      libs_dir    = var.libs_dir,
      onboard_log = var.onboard_log,
      secret_id   = data.aws_secretsmanager_secret.password.id
    }
  )

  depends_on = [aws_network_interface.bigip, aws_eip.bigip]

  tags = {
    Name = format("%s-%d", var.prefix, count.index)
  }
}
