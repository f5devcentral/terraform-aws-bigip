# AWS BIG-IP Terraform Module 
Terraform module to deploy an F5 BIG-IP in AWS.  This module currently supports 1 and 3 nic deployments using the AWS Marketplace PAYG (pay-as-you-go) license.

**NOTE:** You will need to accept the AWS Marketplace offer for your selected BIG-IP AMI.  
**NOTE:** This code is provided for demonstration purposes and is not intended to be used for production deployments. 

## Password Policy (New in 0.1.2)
For security reasons the module no longer generates a random password that is stored in the Terraform state file. Instead, a password must be created in the AWS Secrets Manager and the Secret name must be supplied to the module.  For demonstration purposes, the examples show how to do this using an randomly generated password.

## Dependencies
This module requires that the user has created a password and stored it in the AWS Secret Manager before calling the module. For information on how to do this please refer to the [AWS Secret Manager docs](https://docs.aws.amazon.com/secretsmanager/latest/userguide/manage_create-basic-secret.html).

## Terraform Version
This modules supports Terraform 0.12 and higher

## Example 1-NIC Deployment
```hcl
module bigip {
  source = "f5devcentral/bigip/aws"
  version = "0.1.2"

  prefix            = "bigip"
  f5_instance_count = 1
  ec2_key_name      = "my-key"
  aws_secretmanager_secret_id = "my_bigip_password"
  mgmt_subnet_security_group_ids = [sg-01234567890abcdef]
  vpc_mgmt_subnet_ids = [subnet-01234567890abcdef]
}
```
## Example 3-NIC Deployment
```hcl
module bigip {
  source = "f5devcentral/bigip/aws"
  version = "0.1.2"

  prefix            = "bigip"
  f5_instance_count = 1
  ec2_key_name      = "my-key"
  aws_secretmanager_secret_id = "my_bigip_password"
  mgmt_subnet_security_group_ids = [sg-01234567890abcdef]
  public_subnet_security_group_ids = [sg-01234567890ghijkl]
  private_subnet_security_group_ids = [sg-01234567890mnopqr]
  vpc_mgmt_subnet_ids = [subnet-01234567890abcdef]
  vpc_public_subnet_ids = [subnet-01234567890ghijkl]
  vpc_private_subnet_ids    = [subnet-01234567890mnopqr]
}
```