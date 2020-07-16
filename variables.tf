variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "terraform-aws-bigip-demo"
}

variable "f5_ami_search_name" {
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 Networks BIGIP-14.1.2.6* PAYG - Best 200Mbps*"
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

variable "bigip_map" {
  description = "map of network subnet ids to BIG-IP interface ids"
  type = map(object({
    network_interfaces = map(object({
      subnet_id                 = string
      subnet_security_group_ids = list(string)
      interface_type            = string
      public_ip                 = bool
      private_ips_count         = number
      device_index              = number
      cloudfailover_tag         = string
    }))
  }))
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
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.11.1/f5-declarative-onboarding-1.11.1-1.noarch.rpm"
}
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable AS3_URL {
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.13.2/f5-appsvcs-3.13.2-1.noarch.rpm"
}

## Please check and update the latest TS URL from https://github.com/F5Networks/f5-telemetry-streaming/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable TS_URL {
  description = "URL to download the BIG-IP Telemetry Streaming module"
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.10.0/f5-telemetry-1.10.0-2.noarch.rpm"
}

## Please check and update the latest Failover Extension URL from https://github.com/f5devcentral/f5-cloud-failover-extension/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable CFE_URL {
  description = "URL to download the BIG-IP Cloud Failover Extension module"
  type        = string
  default     = "https://github.com/f5devcentral/f5-cloud-failover-extension/releases/download/v1.1.0/f5-cloud-failover-1.1.0-0.noarch.rpm"
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

variable iam_instance_profile {
  description = "IAM Profile used by the BIG-IP for access to secrets manager, S3, EC2 and Logging"
  type        = string
}

variable custom_user_data {
  description = "Provide a custom bash script or cloud-init script the BIG-IP will run on creation"
  type        = string
  default     = null
}
