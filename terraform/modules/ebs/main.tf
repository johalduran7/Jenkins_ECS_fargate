variable "aws_region" {
  type    = string
  default = ""
}

resource "aws_ssm_parameter" "latest_snapshot_id" {
  name  = "/jenkins/latest_snapshot_id"
  type  = "String"
  value = "null" # Start with an empty value
  lifecycle {
    ignore_changes = [value] # it prevents the value from being updated after the first run of Terraform.
  }
}

data "aws_ssm_parameter" "latest_snapshot_id" {
  name            = "/jenkins/latest_snapshot_id"
  with_decryption = false
  depends_on      = [aws_ssm_parameter.latest_snapshot_id]
}

locals {
  jenkins_snapshot_id = try(data.aws_ssm_parameter.latest_snapshot_id.value, "")
}


resource "aws_ebs_volume" "jenkins_volume" {
  #count             = length(data.aws_ebs_snapshot.latest_jenkins_snapshot.id) > 0 ? 1 : 0
  availability_zone = "${var.aws_region}a"
  # If a snapshot exists, use it; otherwise, create a new volume
  snapshot_id = local.jenkins_snapshot_id != "null" ? local.jenkins_snapshot_id : null
  size        = local.jenkins_snapshot_id == "null" ? 4 : null # Set size only for fresh volumes

  type = "gp3"
  tags = {
    Name      = "jenkins_volume"
    Terraform = "yes"
  }
}

resource "aws_ssm_parameter" "backupable_volume" {
  name  = "/jenkins/volume_id"
  type  = "String"
  value = "null" # Start with an empty value
  lifecycle {
    ignore_changes = [value] # it prevents the value from being updated after the first run of Terraform.
  }
}


output "jenkins_volume_id" {
  value = aws_ebs_volume.jenkins_volume.id
}


output "jenkins_snapshot_id" {
  value = local.jenkins_snapshot_id
}

