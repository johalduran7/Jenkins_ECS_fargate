
#$ ssh-keygen -t rsa -b 4096 -f key_saa -N ""
resource "aws_key_pair" "deployer" {
  key_name   = "${var.env}-deployer-key"
  public_key = file("key_saa.pub")
}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"] # Amazon's official AMI owner ID

  filter {
    name   = "name"
    values = ["al2023-ami-2023.6.20250128.0-kernel-6.1-x86_64"] # Amazon Linux 2 AMI
    #values = ["Amazon Linux 2023 AMI"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "jenkins_master" {
  ami                    = data.aws_ami.amazon_linux.id # Replace with your desired AMI
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name # Replace with your key pair
  vpc_security_group_ids = [aws_security_group.sg_ssh.id, aws_security_group.sg_web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  #user_data = filebase64(var.path_user_data)
  # Configure Spot Instance
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price          = "0.03"     # Set your maximum bid price (e.g., $0.03/hour)
      spot_instance_type = "one-time" # Use "persistent" for long-running workloads
    }
  }
  user_data = <<-EOF
    #!/bin/bash
    # Install Docker
    sudo yum update -y
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user

    # Log in to ECR (if needed)
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.jenkins_ecr_repository_url}

    # Pull the Jenkins image from ECR (if needed)
    docker pull ${var.jenkins_ecr_repository_url}:latest

    LATEST_BACKUP=$(aws s3 ls s3://fargate-jenkins-john-duran/ | grep 'jenkins_volume_backup_' | sort | tail -n 1 | awk '{print $4}')
    echo "Latest backup: $LATEST_BACKUP"

    # Copy backup from S3
    aws s3 cp s3://fargate-jenkins-john-duran/$LATEST_BACKUP $HOME/backup.tar.gz

    # Create a directory for Jenkins data
    mkdir -p $HOME/jenkins_data
    sudo tar -xzf $HOME/backup.tar.gz -C $HOME/jenkins_data


    # Run the Jenkins container with the restored data
    docker run -d --name jenkins -p 8080:8080 -v $HOME/jenkins_data:/var/jenkins_home ${var.jenkins_ecr_repository_url}:latest
  EOF
  tags = {
    Name      = "jenkins_master"
    Terraform = "yes"
  }

}



locals {
  SSM_url = <<EOT
  aws ssm start-session --region ${var.aws_region} --profile personal_aws --target ${aws_instance.jenkins_master.id} --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["8080"], "localPortNumber":["8080"]}'
  EOT
}


