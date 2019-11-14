# AWS BIG-IP Terraform Module 
Terraform module to deploy an F5 BIG-IP in AWS.  This module currently supports 1 and 3 nic deployments and defaults to using the AWS Marketplace PAYG (pay-as-you-go) 200Mbps BEST license.  If you would like to use a bring your own license (BYOL) AMI the set the *f5_ami_search_name* variable accordingly.

**NOTE:** You will need to accept the AWS Marketplace offer for your selected BIG-IP AMI.  
**NOTE:** This code is provided for demonstration purposes and is not intended to be used for production deployments. 

## Password Policy (New in 0.1.2)
For security reasons the module no longer generates a random password that is stored in the Terraform state file. Instead, a password must be created in the AWS Secrets Manager and the Secret name must be supplied to the module.  For demonstration purposes, the examples show how to do this using an randomly generated password.

## Dependencies
This module requires that the user has created a password and stored it in the AWS Secret Manager before calling the module. For information on how to do this please refer to the [AWS Secret Manager docs](https://docs.aws.amazon.com/secretsmanager/latest/userguide/manage_create-basic-secret.html).

## Terraform Version
This modules supports Terraform 0.12 and higher

## Examples
We have provided some common deployment examples below.  However, if you would like to see full end-to-end examples with the creation of all required objects check out the [examples](https://github.com/f5devcentral/terraform-aws-bigip/tree/master/examples) folder in the [GitHub repository](https://github.com/f5devcentral/terraform-aws-bigip/).

### Example 1-NIC Deployment PAYG
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
### Example 1-NIC Deployment BYOL
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
  f5_ami_search_name = "F5 Networks BIGIP-14.0.1*BYOL*All Modules 1 Boot*"
}
```

### Example 2-NIC Deployment PAYG
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
  vpc_mgmt_subnet_ids = [subnet-01234567890abcdef]
  vpc_public_subnet_ids = [subnet-01234567890ghijkl]
}
```

### Example 3-NIC Deployment PAYG
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

## Finding AWS Machine Images (AMI)
If there is a specific F5 BIG-IP AMI you would like to use you can update the f5_ami_search_name variable to reflect the AMI name or name pattern you are looking for.

Example to find F5 AMIs for PAYG 200Mbps BEST licensing:
```bash
aws ec2 describe-images --owners 679593333241 --filters "Name=name, Values=F5 Networks BIGIP-14.0.1-0.0.14* PAYG - Best 200Mbps*"
```

Example to find F5 AMIs for BYOL 200Mbps BEST licensing:
```bash
aws ec2 describe-images --owners 679593333241 --filters "Name=name, Values=F5 Networks BIGIP-14.0.1*BYOL*All Modules 1 Boot*"
```