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
