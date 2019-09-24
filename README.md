# AWS BIG-IP Terraform Module 
Terraform module to deploy an F5 BIG-IP in AWS.

## Terraform Version
This modules supports Terraform 0.12 and higher

## Usage
```hcl
module bigip {
  source = "../../"

  prefix            = "bigip"
  f5_instance_count = 1
  ec2_key_name      = "cody-key"
  vpc_security_group_ids = [
    sg-01234567890abcdef
  ]
  vpc_mgmt_subnet_ids = subnet-01234567890abcdef

  private_key_path  = "~/.ssh/cody-key.pub"
  
}
```
