locals {
  task_definition_revision = "${aws_ecs_task_definition.jenkins_slave_fargate_task.family}:${aws_ecs_task_definition.jenkins_slave_fargate_task.revision}"
}

output "task_definition" {
  value = local.task_definition_revision
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}

output "ecs_task_execution_role_slave_jenkins" {
  value = aws_iam_role.ecs_task_execution_role_slave_jenkins.arn
}

output "ecs_task_role_slave_jenkins" {
  value = aws_iam_role.ecs_task_role_slave_jenkins.arn
}

output "jenkins_cluster_arn" {
  value = aws_ecs_cluster.jenkins_cluster.arn
}


