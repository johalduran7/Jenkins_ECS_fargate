output "s3_bucket_name" {
  value = var.s3_bucket_name
}

output "ecr_repo_name" {
  value = var.ecr_repo_name
}

output "SSM_command_session" {
  value = module.ec2_master.SSM_command_session
}
