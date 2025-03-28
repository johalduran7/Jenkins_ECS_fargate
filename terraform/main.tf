## Create VPC
# module "vpc" {
#   source                = "./modules/vpc"
#   env                   = var.env
#   vpc_name              = var.vpc_name
#   aws_region            = var.aws_region
#   cidr_block            = var.cidr_block
#   public_subnet_a_cidr  = var.public_subnet_a_cidr
#   public_subnet_a_name  = var.public_subnet_a_name
#   public_subnet_b_cidr  = var.public_subnet_b_cidr
#   public_subnet_b_name  = var.public_subnet_b_name
#   private_subnet_a_cidr = var.private_subnet_a_cidr
#   private_subnet_a_name = var.private_subnet_a_name
#   private_subnet_b_cidr = var.private_subnet_b_cidr
#   private_subnet_b_name = var.private_subnet_b_name

# }
module "ecr" {
  source        = "./modules/ecr"
  aws_region    = var.aws_region
  ecr_repo_name = var.ecr_repo_name
}

module "s3" {
  source         = "./modules/s3"
  s3_bucket_name = var.s3_bucket_name
}

module "ebs" {
  source     = "./modules/ebs"
  aws_region = var.aws_region

}

module "ecs_slave" {
  source                       = "./modules/ecs_slave"
  env                          = var.env
  jenkins_cloud_name           = var.jenkins_cloud_name
  jenkins_slave_repository_url = module.ecr.jenkins_slave_repository_url
}



module "ec2_master" {
  source                                = "./modules/ec2_master"
  jenkins_ecr_repository_url            = module.ecr.jenkins_ecr_repository_url
  env                                   = var.env
  s3_bucket_name                        = var.s3_bucket_name
  aws_s3_bucket_arn                     = module.s3.aws_s3_bucket_arn
  jenkins_volume_id                     = module.ebs.jenkins_volume_id
  aws_region                            = var.aws_region
  jenkins_cloud_name                    = var.jenkins_cloud_name
  task_definition                       = module.ecs_slave.task_definition
  ecs_sg_id                             = module.ecs_slave.ecs_sg_id
  ecs_task_execution_role_slave_jenkins = module.ecs_slave.ecs_task_execution_role_slave_jenkins
  ecs_task_role_slave_jenkins           = module.ecs_slave.ecs_task_role_slave_jenkins
  jenkins_cluster_arn                   = module.ecs_slave.jenkins_cluster_arn
}


module "lambda" {
  source = "./modules/lambda"
}

module "eventBridge" {
  source                            = "./modules/eventBridge"
  lambda_jenkins_arn                = module.lambda.lambda_jenkins_arn
  lambda_jenkins_name               = module.lambda.lambda_jenkins_name
  lambda_jenkins_delete_volume_arn  = module.lambda.lambda_jenkins_delete_volume_arn
  lambda_jenkins_delete_volume_name = module.lambda.lambda_jenkins_delete_volume_name

}


