output "s3_bucket_name" {
  value = var.s3_bucket_name
}

output "ecr_repo_name" {
  value = var.ecr_repo_name
}
output "jenkins_snapshot_id" {
  value     = module.ebs.jenkins_snapshot_id
  sensitive = true
}
output "jenkins_volume_id" {
  value     = module.ebs.jenkins_volume_id
  sensitive = true
}



# output "SSM_command_session" {
#   value = module.ec2_master.SSM_command_session
# }

# output "lambda_jenkins_name" {
#   value = module.lambda.lambda_jenkins_name
# }

# output "lambda_jenkins_arn" {
#   value = module.lambda.lambda_jenkins_arn
# }
