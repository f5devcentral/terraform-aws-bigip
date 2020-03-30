#
# Set local values
#
locals {
  network_subnets = flatten([
    for id, subnet_data in var.bigip_subnet_map : [
      for subnet_id in subnet_data.subnet_ids : {
        id                               = id
        subnet_id                        = subnet_id
        security_groups                  = subnet_data.subnet_security_group_ids
        interface_type                   = subnet_data.interface_type
        public_ip                        = subnet_data.public_ip
        number_of_additional_private_ips = subnet_data.number_of_additional_private_ips
      }
    ]
  ])
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
    for subnet in local.network_subnets : "${subnet.id}:${subnet.subnet_id}" => subnet
  }
  subnet_id       = each.value.subnet_id
  security_groups = each.value.security_groups
  tags            = { "bigip_interface_type" : each.value.interface_type }
}

#
# add an elastic IP to the BIG-IP management interface
#
# data "aws_network_interface" "mgmt" {
#   filter = {
#     vpc-id = 
#   }
# }

resource "aws_eip" "mgmt" {
  for_each = {
    for interface in aws_network_interface.bigip : interface.id => {
      id = (lookup(interface.tags, "bigip_interface_type", null) == "mgmt" ? interface.id : null)
      # id = interface.id
    }
  }
  network_interface = each.value.id
  vpc               = true
}


# resource "aws_eip" "mgmt" {
#   count             = var.mgmt_eip ? length(var.vpc_mgmt_subnet_ids) : 0
#   network_interface = aws_network_interface.mgmt[count.index].id
#   vpc               = true
# }

# #
# # Deploy BIG-IP
# #
# resource "aws_instance" "f5_bigip" {
#   # determine the number of BIG-IPs to deploy
#   count                = var.f5_instance_count
#   instance_type        = var.ec2_instance_type
#   ami                  = data.aws_ami.f5_ami.id
#   iam_instance_profile = aws_iam_instance_profile.bigip_profile.name

#   key_name = var.ec2_key_name

#   root_block_device {
#     delete_on_termination = true
#   }

#   # set the network interfaces
#   dynamic "network_interface" {
#     for_each = var.bigip_subnet_map

#     content {
#       network_interface_id = network_interface.value.network_interface_id[count.index]
#       device_index         = network_interface_id.value.device_index
#     }
#   }

#   # # set the mgmt interface 
#   # dynamic "network_interface" {
#   #   for_each = toset([aws_network_interface.mgmt[count.index].id])

#   #   content {
#   #     network_interface_id = network_interface.value
#   #     device_index         = 0
#   #   }
#   # }

#   # # set the public interface only if an interface is defined
#   # dynamic "network_interface" {
#   #   for_each = length(aws_network_interface.public) > count.index ? toset([aws_network_interface.public[count.index].id]) : toset([])

#   #   content {
#   #     network_interface_id = network_interface.value
#   #     device_index         = 1
#   #   }
#   # }

#   # # set the 3rd private interface only if an interface is defined
#   # dynamic "network_interface" {
#   #   for_each = length(aws_network_interface.private) > count.index ? toset([aws_network_interface.private[count.index].id]) : toset([])

#   #   content {
#   #     network_interface_id = network_interface.value
#   #     device_index         = 2
#   #   }
#   # }

#   # # set the 4th private interface only if an interface is defined
#   # dynamic "network_interface" {
#   #   for_each = length(aws_network_interface.private) > (count.index + length(local.azs)) ? toset([aws_network_interface.private[count.index * 2].id]) : toset([])

#   #   content {
#   #     network_interface_id = network_interface.value
#   #     device_index         = 3
#   #   }
#   # }

#   # build user_data file from template
#   user_data = templatefile(
#     "${path.module}/f5_onboard.tmpl",
#     {
#       DO_URL      = var.DO_URL,
#       AS3_URL     = var.AS3_URL,
#       TS_URL      = var.TS_URL,
#       libs_dir    = var.libs_dir,
#       onboard_log = var.onboard_log,
#       secret_id   = var.aws_secretmanager_secret_id
#     }
#   )

#   depends_on = [aws_eip.mgmt]

#   tags = {
#     Name = format("%s-%d", var.prefix, count.index)
#   }
# }
