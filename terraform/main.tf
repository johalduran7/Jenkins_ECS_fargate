# Create VPC
module "vpc" {
  source                = "./modules/vpc"
  env                   = var.env
  vpc_name              = var.vpc_name
  aws_region            = var.aws_region
  cidr_block            = var.cidr_block
  public_subnet_a_cidr  = var.public_subnet_a_cidr
  public_subnet_a_name  = var.public_subnet_a_name
  public_subnet_b_cidr  = var.public_subnet_b_cidr
  public_subnet_b_name  = var.public_subnet_b_name
  private_subnet_a_cidr = var.private_subnet_a_cidr
  private_subnet_a_name = var.private_subnet_a_name
  private_subnet_b_cidr = var.private_subnet_b_cidr
  private_subnet_b_name = var.private_subnet_b_name

}