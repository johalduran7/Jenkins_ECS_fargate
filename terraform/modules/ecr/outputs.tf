output "jenkins_ecr_repository_url" {
  value = aws_ecr_repository.jenkins.repository_url
}

output "jenkins_slave_repository_url" {
  value = aws_ecr_repository.jenkins_slave.repository_url
}
