#
# Variable for the EC2 Key 
# Set via CLI or via terraform.tfvars file
#
variable "ec2_key_name" {
  description = "AWS EC2 Key name for SSH access"
  type        = string
}

variable "AccessKeyID" {}

variable "SecretAccessKey" {}
