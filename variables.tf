variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "terraform-aws-bigip-demo"
}


variable "create_vpc" {
  description = "Should a new VPC be created for this BIG-IP deployment"
  type        = bool
  default     = true
}

variable "cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable azs {
  description = "AWS Availability Zones to create the VPC in"
  type        = list
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_numbers" {
  description = "List of 8-bit numbers of subnets of the VPC cidr"
  type        = list
  default     = [1, 2, 3]
}

variable "private_subnet_numbers" {
  description = "List of 8-bit numbers of subnets of the VPC cidr"
  type        = list
  default     = [11, 12, 13]
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "allowed_mgmt_cidr" {
  description = "CIDR block that is allowed to access the BIG-IP management interface"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_app_cidr" {
  description = "CIDR block that is allowed to access applications"
  type        = string
  default     = "0.0.0.0/0"
}
