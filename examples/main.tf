

locals {
  bigip_map = {
    0 = {
      network_interfaces = {
        0 = {
          subnet_id = aws_subnet.mgmt["us-west-2a:management:0"].id
          subnet_security_group_ids = [
            module.bigip_mgmt_sg.this_security_group_id
          ]
          interface_type    = "mgmt"
          public_ip         = true
          private_ips_count = 0
        },
        1 = {
          subnet_id = aws_subnet.public["us-west-2a:public:0"].id
          subnet_security_group_ids = [
            module.bigip_sg.this_security_group_id
          ]
          interface_type    = "public"
          public_ip         = true
          private_ips_count = 0
        }
        2 = {
          subnet_id = aws_subnet.private["us-west-2a:private:0"].id
          subnet_security_group_ids = [
            module.bigip_sg.this_security_group_id
          ]
          interface_type    = "private"
          public_ip         = false
          private_ips_count = 0
        }
        3 = {
          subnet_id = aws_subnet.private["us-west-2a:private:1"].id
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
          subnet_id = aws_subnet.mgmt["us-west-2b:management:0"].id
          subnet_security_group_ids = [
            module.bigip_mgmt_sg.this_security_group_id
          ]
          interface_type    = "mgmt"
          public_ip         = true
          private_ips_count = 0
        },
        1 = {
          subnet_id = aws_subnet.public["us-west-2b:public:0"].id
          subnet_security_group_ids = [
            module.bigip_sg.this_security_group_id
          ]
          interface_type    = "public"
          public_ip         = true
          private_ips_count = 0
        }
        2 = {
          subnet_id = aws_subnet.private["us-west-2b:private:0"].id
          subnet_security_group_ids = [
            module.bigip_sg.this_security_group_id
          ]
          interface_type    = "private"
          public_ip         = false
          private_ips_count = 0
        }
        3 = {
          subnet_id = aws_subnet.private["us-west-2b:private:1"].id
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
  iam_instance_profile        = aws_iam_instance_profile.bigip_profile.name
}
