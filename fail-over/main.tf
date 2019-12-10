#
# Create the BIG-IP appliances
#
module "bigip" {
    # once the multiple-public-ips branch is merged this can be changed to
    # source = '../'
    source = "github.com/f5devcentral/terraform-aws-bigip?ref=multiple-public-ips"

    prefix                            = var.prefix
    aws_secretmanager_secret_id       = var.aws_secretmanager_secret_id
    f5_ami_search_name                = var.f5_ami_search_name
    f5_instance_count                 = var.f5_instance_count
    ec2_key_name                      = var.ec2_key_name
    ec2_instance_type                 = var.ec2_instance_type
    DO_URL                            = var.DO_URL
    application_instance_count        = length(var.applications)
    mgmt_subnet_security_group_ids    = var.mgmt_subnet_security_group_ids
    public_subnet_security_group_ids  = var.public_subnet_security_group_ids
    private_subnet_security_group_ids = var.private_subnet_security_group_ids
    vpc_public_subnet_ids             = var.vpc_public_subnet_ids
    vpc_private_subnet_ids            = var.vpc_private_subnet_ids
    vpc_mgmt_subnet_ids               = var.vpc_mgmt_subnet_ids
}



locals {
    # create failover tags per application
    failover_tags = [
        for num in range(length(var.applications)):
        {
        # tags required for failover extension support
        # https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/aws.html#requirements
        "VIPS" = join(", ",[
            for nic in data.aws_network_interface.bigip_public_nics:
            element(nic.private_ips,num)
            ]),
        "f5_cloud_failover_label" = "${var.prefix}-${var.applications[num]}-failover-deployment-${var.randomid}"
        }    
    ]
}


resource "aws_eip" "application_eips" {
    count                     = length(var.applications)
    vpc                       = true
    network_interface         = "${data.aws_network_interface.bigip_public_nics[0].id}"
    associate_with_private_ip = element(
        data.aws_network_interface.bigip_public_nics[0].private_ips,count.index
    )
    tags = merge(
        local.failover_tags[count.index],
        { Name = format("%s-%s-eip-%s-%s", var.prefix, var.applications[count.index],var.randomid,count.index)}
    )
}

data "aws_network_interface" "bigip_public_nics" {
    count = length(module.bigip.public_nic_ids)
    id = module.bigip.public_nic_ids[count.index]
}

