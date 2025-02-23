
# data "aws_ebs_snapshot" "latest_jenkins_snapshot" {
#   most_recent = true

#   filter {
#     name   = "tag:Name"
#     values = ["jenkins_backup"]
#   }
# }
resource "aws_ssm_parameter" "latest_snapshot_id" {
  name  = "/jenkins/latest_snapshot_id"
  type  = "String"
  value = "null" # Start with an empty value
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
  availability_zone = var.instance_az
  # If a snapshot exists, use it; otherwise, create a new volume
  snapshot_id = local.jenkins_snapshot_id != "null" ? local.jenkins_snapshot_id : null
  size        = local.jenkins_snapshot_id == "null" ? 4 : null # Set size only for fresh volumes

  type = "gp3"
  tags = {
    Name      = "jenkins_volume"
    Terraform = "yes"
  }
}
resource "aws_volume_attachment" "jenkins_attachment" {
  device_name = "/dev/xvdf" # Adjust based on your AMI
  volume_id   = aws_ebs_volume.jenkins_volume.id
  instance_id = var.instance_id
}


variable "instance_id" {
  type    = string
  default = ""
}
variable "instance_az" {
  type    = string
  default = ""
}
