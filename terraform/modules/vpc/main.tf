# create a vpc with CIDR 10.0.0.0/16, ipv4, default tenancy, Tag name DemoVPC and create separate variables to modify as inputs

# VPC Resource
resource "aws_vpc" "app_vpc" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "${var.env}-${var.vpc_name}"
    Terraform = "yes"
  }
}