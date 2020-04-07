variable "specification" {
  default = {
    "default" = {
      number_public_interfaces  = 0
      number_private_interfaces = 0
      ec2_instance_type         = "m4.large"
    }
    "2nic" = {
      number_public_interfaces  = 1
      number_private_interfaces = 0
      ec2_instance_type         = "m4.large"
    }
    "3nic" = {
      number_public_interfaces  = 1
      number_private_interfaces = 1
      ec2_instance_type         = "m4.xlarge"
    }
    "4nic" = {
      number_public_interfaces  = 1
      number_private_interfaces = 2
      ec2_instance_type         = "m4.xlarge"
    }
    "8nic" = {
      number_public_interfaces  = 1
      number_private_interfaces = 6
      ec2_instance_type         = "m4.xlarge"
    }
  }
}

variable "ec2_key_name" {
  description = "AWS EC2 Key name for SSH access"
  type        = string
}

variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "tf-aws-bigip"
}

variable "region" {
  description = "AWS Region for the VPC"
  type        = string
  default     = "us-west-1"
}

variable "cidr" {
  description = "AWS VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_mgmt_cidr" {
  description = "CIDR of allowed IPs for the BIG-IP management interface"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_app_cidr" {
  description = "CIDR of allowed IPs for the BIG-IP Virtual Servers"
  type        = string
  default     = "0.0.0.0/0"
}

variable cfe_route_table_id {
  description = "AWS Route Table ID for the table Cloud Failover Extension needs to update"
  type        = string
  default     = "*"
}

variable cfe_ec2_resource_tag {
  description = "EC2 tag used by Cloud Failover Extension"
  type        = string
  default     = "bigip-cfe"
}
