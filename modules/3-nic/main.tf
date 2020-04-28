locals {
  azs  = var.azs
  cidr = var.cidr
  management_interface_count = 1
  public_interface_count = 1
  private_interface_count = 1
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
    "management" = var.management_security_groups
    "public" = var.public_security_groups
    "private" = var.private_security_groups
  }

  bigip_map = {
    for num in range(length(local.azs)): num => {
        network_interfaces = {
          for subnet_key, subnet in var.vpcsubnets:
          subnet_key => {
            subnet_id                 = subnet.id
            subnet_security_group_ids = lookup(local.interface_security_groups,subnet.tags.subnet_type,[])
            interface_type            = subnet.tags.subnet_type
            public_ip                 = (subnet.tags.subnet_type == "management" || subnet.tags.subnet_type == "public") ? true : false
            private_ips_count         = 0 # this needs to be parameterized
            device_index              = subnet.tags.bigip_device_index
          }
          if subnet.availability_zone == local.azs[num]
        }
    }
  }

}


module bigip {
  source = "../../"

  prefix                      = var.prefix
  ec2_instance_type           = var.ec2_instance_type
  ec2_key_name                = var.ec2_key_name
  aws_secretmanager_secret_id = var.aws_secretmanager_secret_id
  bigip_map                   = local.bigip_map
  iam_instance_profile        = var.iam_instance_profile
}