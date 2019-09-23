# New VPC with a 1-nic BIG-IP in each AZ
This examples deploys a new VPC and builds a 1-nic BIG-IP in each availability zones

## Usage
To run this example run the following commands:
```bash
terraform init
terraform plan
terraform apply --auto-approve 
```

**Note:** this examples deploys resources that will cost money.  Please run the following command to destroy your environment when finished:
```bash
terraform destroy --auto-approve
```