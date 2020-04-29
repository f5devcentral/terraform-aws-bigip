variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "terraform-aws-bigip-demo"
}

variable "f5_ami_search_name" {
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 Networks BIGIP-14.* PAYG - Best 200Mbps*"
}

variable "f5_instance_count" {
  description = "Number of BIG-IPs to deploy"
  type        = number
  default     = 1
}

variable "application_endpoint_count" {
  description = "number of public application addresses to assign"
  type        = number
  default     = 2
}

variable "ec2_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "m4.large"
}

variable "ec2_key_name" {
  description = "AWS EC2 Key name for SSH access"
  type        = string
}

variable "vpc_public_subnet_ids" {
  description = "AWS VPC Subnet id for the public subnet"
  type        = list
  default     = []
}

variable "vpc_private_subnet_ids" {
  description = "AWS VPC Subnet id for the private subnet"
  type        = list
  default     = []
}

variable "vpc_mgmt_subnet_ids" {
  description = "AWS VPC Subnet id for the management subnet"
  type        = list
  default     = []
}

variable "mgmt_eip" {
  description = "Enable an Elastic IP address on the management interface"
  type        = bool
  default     = true
}

variable "mgmt_subnet_security_group_ids" {
  description = "AWS Security Group ID for BIG-IP management interface"
  type        = list
  default     = []
}

variable "public_subnet_security_group_ids" {
  description = "AWS Security Group ID for BIG-IP public interface"
  type        = list
  default     = []
}

variable "private_subnet_security_group_ids" {
  description = "AWS Security Group ID for BIG-IP private interface"
  type        = list
  default     = []
}

variable "aws_secretmanager_secret_id" {
  description = "AWS Secret Manager Secret ID that stores the BIG-IP password"
  type        = string
}


## Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable DO_URL {
  description = "URL to download the BIG-IP Declarative Onboarding module"
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.8.0/f5-declarative-onboarding-1.8.0-2.noarch.rpm"
}
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable AS3_URL {
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.14.0/f5-appsvcs-3.14.0-4.noarch.rpm"
}

## Please check and update the latest TS URL from https://github.com/F5Networks/f5-telemetry-streaming/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable TS_URL {
  description = "URL to download the BIG-IP Telemetry Streaming Extension (TS) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.8.0/f5-telemetry-1.8.0-1.noarch.rpm"
}

variable "libs_dir" {
  description = "Directory on the BIG-IP to download the A&O Toolchain into"
  type        = string
  default     = "/config/cloud/aws/node_modules"
}

variable onboard_log {
  description = "Directory on the BIG-IP to store the cloud-init logs"
  type        = string
  default     = "/var/log/startup-script.log"
}
