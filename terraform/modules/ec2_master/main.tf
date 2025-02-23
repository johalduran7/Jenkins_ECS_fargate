
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
  root_block_device {
    volume_size = 8 # Increase to store Jenkins data
    volume_type = "gp3"
  }
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Fetch the latest snapshot ID from SSM
    SNAPSHOT_ID=$(aws ssm get-parameter --name "/jenkins/latest_snapshot_id" --query "Parameter.Value" --output text --region ${var.aws_region} || echo "")

    # Install Docker
    sudo yum update -y
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user

    # Log in to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.jenkins_ecr_repository_url}

    # Pull the latest Jenkins image
    docker pull ${var.jenkins_ecr_repository_url}:latest

    if [[ -z "$SNAPSHOT_ID" || "$SNAPSHOT_ID" == "None" ]]; then
        echo "No snapshot found. Pulling data from S3 backup."

        # If an extra volume (xvdf) is attached, delete it
        if lsblk | grep -q "xvdf"; then
            echo "Unneeded volume found (xvdf). Deleting..."
            VOLUME_ID=$(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$(curl -s http://169.254.169.254/latest/meta-data/instance-id) --query "Volumes[?Attachments[?Device=='/dev/xvdf']].VolumeId" --output text --region ${var.aws_region})
            aws ec2 detach-volume --volume-id $VOLUME_ID --region ${var.aws_region}
            aws ec2 delete-volume --volume-id $VOLUME_ID --region ${var.aws_region}
        fi
        
        # Find the latest backup file in S3
        LATEST_BACKUP=$(aws s3 ls s3://${var.s3_bucket_name}/ | grep 'jenkins_volume_backup_' | sort | tail -n 1 | awk '{print $4}')
        echo "Latest backup found: $LATEST_BACKUP"

        if [[ -n "$LATEST_BACKUP" ]]; then
            # Download and extract the backup
            aws s3 cp s3://${var.s3_bucket_name}/$LATEST_BACKUP $HOME/backup.tar.gz
            mkdir -p $HOME/jenkins_data
            sudo tar -xzf $HOME/backup.tar.gz -C $HOME/jenkins_data
        fi

    else
        echo "Snapshot found: $SNAPSHOT_ID. Restoring from EBS volume."

        # Check if the extra volume is attached
        if lsblk | grep -q "xvdf"; then
            echo "Mounting attached volume..."
            sudo mkdir -p /mnt/jenkins
            sudo mount /dev/xvdf /mnt/jenkins

            echo "Copying data to Docker volume..."
            mkdir -p $HOME/jenkins_data
            sudo rsync -av /mnt/jenkins/ /home/ec2-user/jenkins_data/

            echo "Unmounting and deleting attached volume..."
            sudo umount /mnt/jenkins
            aws ec2 delete-volume --volume-id $(lsblk -no UUID /dev/xvdf) --region ${var.aws_region}
        fi
    fi

    # Run Jenkins in Docker with the restored data
    docker run -d --name jenkins -p 8080:8080 -v /home/ec2-user/jenkins_data:/var/jenkins_home ${var.jenkins_ecr_repository_url}:latest
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


