# AWS BIG-IP Terraform Module 
Terraform module to deploy an F5 BIG-IP in AWS.  This module currently supports 1 and 3 nic deployments using the AWS Marketplace PAYG (pay-as-you-go) license.

**NOTE:** You will need to accept the AWS Marketplace offer for your selected BIG-IP AMI.  
**NOTE:** This code is provided for demonstration purposes and is not intended to be used for production deployments. 

## Terraform Version
This modules supports Terraform 0.12 and higher

## Example 1-NIC Deployment
```hcl
module bigip {
  source = "f5devcentral/bigip/aws"

  prefix            = "bigip"
  f5_instance_count = 1
  ec2_key_name      = "my-key"
  mgmt_subnet_security_group_ids = [sg-01234567890abcdef]
  vpc_mgmt_subnet_ids = [subnet-01234567890abcdef]
}
```
## Example 3-NIC Deployment
```hcl
module bigip {
  source = "f5devcentral/bigip/aws"

  prefix            = "bigip"
  f5_instance_count = 1
  ec2_key_name      = "my-key"
  mgmt_subnet_security_group_ids = [sg-01234567890abcdef]
  public_subnet_security_group_ids = [sg-01234567890ghijkl]
  private_subnet_security_group_ids = [sg-01234567890mnopqr]
  vpc_mgmt_subnet_ids = [subnet-01234567890abcdef]
  vpc_private_subnet_ids = [subnet-01234567890ghijkl]
  vpc_mgmt_subnet_ids    = [subnet-01234567890mnopqr]
}
```