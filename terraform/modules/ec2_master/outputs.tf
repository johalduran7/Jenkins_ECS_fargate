output "SSM_command_session" {
  value = local.SSM_url
}

output "instance_id" {
  value = aws_instance.jenkins_master.id
}

output "instance_az" {
  value = aws_instance.jenkins_master.availability_zone
}