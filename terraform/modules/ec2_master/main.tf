
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
    #values = ["al2023-ami-2023.6.20250128.0-kernel-6.1-x86_64"] # Amazon Linux 2 AMI
    #values = ["Amazon Linux 2023 AMI"]
    #values = ["al2023-ami-kernel-default-x86_64"]
    #values = ["al2023-ami-*-x86_64"] #it increased the size of snapshot to 30GB
    values = ["al2023-ami-2023.7.20250609.0-kernel-6.12-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# find the proper snapshot dependinng on the size
# aws ec2 describe-images \
#   --owners amazon \
#   --filters "Name=name,Values=al2023-ami-*-x86_64" \
#            "Name=virtualization-type,Values=hvm" \
#   --query "Images[*].{
#     AMI_ID: ImageId,
#     Name: Name,
#     Created: CreationDate,
#     SnapshotId: BlockDeviceMappings[0].Ebs.SnapshotId
#   }" \
#   --output json | jq -r '.[] | [.AMI_ID, .Name, .Created, .SnapshotId] | @tsv' | while IFS=$'\t' read -r ami name date snapshot; do
#   size=$(aws ec2 describe-snapshots --snapshot-ids "$snapshot" --query "Snapshots[0].VolumeSize" --output text)
#   printf "%-20s %-55s %-25s %-20s %s GB\n" "$ami" "$name" "$date" "$snapshot" "$size"
# done


data "aws_subnets" "az_a_subnets" {
  filter {
    name   = "availability-zone"
    values = ["${var.aws_region}a"] # Change this to your desired AZ
  }
}

data "aws_subnet" "selected_subnet" {
  id = tolist(data.aws_subnets.az_a_subnets.ids)[0]
}


resource "aws_instance" "jenkins_master" {
  ami                    = data.aws_ami.amazon_linux.id # Replace with your desired AMI
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name # Replace with your key pair
  vpc_security_group_ids = [aws_security_group.sg_ssh.id, aws_security_group.sg_web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  #availability_zone      = "${var.aws_region}a"
  subnet_id = data.aws_subnet.selected_subnet.id

  # aws ec2 describe-spot-price-history \
  #       --instance-types t2.micro \
  #       --availability-zone us-east-1a \
  #       --start-time $(date --date="1 hour ago" --utc +%Y-%m-%dT%H:%M:%SZ) \
  #       --query 'SpotPriceHistory[?ProductDescription==`Linux/UNIX`].SpotPrice | sort(@) | [0]' \
  #       --output text
  root_block_device {
    volume_size = 8 # Increase to store Jenkins data
    volume_type = "gp3"
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # Allows both IMDSv1 and IMDSv2, set to required if you want only IMDSv2
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
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/instance-id")
    PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/local-ipv4")

    # Pull the latest Jenkins image
    docker pull ${var.jenkins_ecr_repository_url}:latest
    while true; do
        # Check if the volume is attached to the EC2 instance
          VOLUME_ID=$(aws ec2 describe-volumes \
        --filters "Name=attachment.instance-id,Values=$INSTANCE_ID" \
        --query "Volumes[?Attachments[?Device=='/dev/xvdf']].VolumeId" \
        --output text --region ${var.aws_region})
        ATTACHMENT_STATE=$(aws ec2 describe-volumes --volume-id $VOLUME_ID --query "Volumes[0].Attachments[?InstanceId=='$INSTANCE_ID'].State" --output text --region ${var.aws_region})
        
        if [[ "$ATTACHMENT_STATE" != "attached" ]]; then
            echo "Volume is not attached yet. Waiting..."
            sleep 1
        else
            echo "Volume is attached!!"
            break
        fi
    done
    sudo mkdir -p /mnt/jenkins_data
    sudo rm -rf /mnt/jenkins_data/*
    sudo mount /dev/xvdf /mnt/jenkins_data
    CONFIG_FILE="/mnt/jenkins_data/config.xml"
    update_config_xml() {
      TASK_DEFINITION="${var.task_definition}"
      SUBNET="${data.aws_subnet.selected_subnet.id}"
      SECURITY_GROUP="${var.ecs_sg_id}"
      TASK_ROLE="${var.ecs_task_execution_role_slave_jenkins}"
      EXECUTION_ROLE="${var.ecs_task_execution_role_slave_jenkins}"
      CLUSTER="${var.jenkins_cluster_arn}"
      REGION="${var.aws_region}"
      JENKINS_URL="http://$PRIVATE_IP:8080"
      

      awk -v task="$TASK_DEFINITION" \
          -v subnet="$SUBNET" \
          -v sg="$SECURITY_GROUP" \
          -v taskrole="$TASK_ROLE" \
          -v executionrole="$EXECUTION_ROLE" \
          -v cluster="$CLUSTER" \
          -v region="$REGION" \
          -v jenkins_url="$JENKINS_URL" '
      BEGIN {inside_ecs=0; inside_fargate=0} 

      # Identify ECS task definition block
      /<label>${var.jenkins_cloud_name}<\/label>/ {inside_ecs=1} 
      inside_ecs && /<taskDefinitionOverride>/ {sub(/>.*</, ">" task "<")} 
      inside_ecs && /<subnets>/ {sub(/>.*</, ">" subnet "<")} 
      inside_ecs && /<securityGroups>/ {sub(/>.*</, ">" sg "<")} 
      inside_ecs && /<taskrole>/ {sub(/>.*</, ">" taskrole "<")} 
      inside_ecs && /<executionRole>/ {sub(/>.*</, ">" executionrole "<")} 
      inside_ecs && /<\/cloud>/ {inside_ecs=0} 

      # Identify Fargate block
      /<name>${var.jenkins_cloud_name}<\/name>/ {inside_fargate=1} 
      inside_fargate && /<cluster>/ {sub(/>.*</, ">" cluster "<")} 
      inside_fargate && /<regionName>/ {sub(/>.*</, ">" region "<")} 
      inside_fargate && /<jenkinsUrl>/ {sub(/>.*</, ">" jenkins_url "<")}
      inside_fargate && /<\/cloud>/ {inside_fargate=0} 

      {print}' "$CONFIG_FILE" > config.xml.tmp && mv config.xml.tmp "$CONFIG_FILE"
    }

    if grep "<name>${var.jenkins_cloud_name}</name> *$" "$CONFIG_FILE" "$CONFIG_FILE"; then
      update_config_xml
    fi

    if [[ -z "$SNAPSHOT_ID" || "$SNAPSHOT_ID" == "null" ]]; then
      echo "No snapshot found. Pulling data from S3 backup."
      # Find the latest backup file in S3
      LATEST_BACKUP=$(aws s3 ls s3://${var.s3_bucket_name}/ | grep 'jenkins_volume_backup_' | sort | tail -n 1 | awk '{print $4}')
      echo "Latest backup found: $LATEST_BACKUP"

      if [[ -n "$LATEST_BACKUP" ]]; then
          # Download and extract the backup
          aws s3 cp s3://${var.s3_bucket_name}/$LATEST_BACKUP /home/ec2-user/backup.tar.gz   
          sudo tar -xzf /home/ec2-user/backup.tar.gz -C /mnt/jenkins_data
          #rm -rf /home/ec2-user/backup.tar.gz
      fi
    fi


    # # Run Jenkins in Docker with the restored data
    echo "Running docker"
    DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    echo $DOCKER_GID  
    docker run -d --name jenkins -p 8080:8080 -p 50000:50000  -v /mnt/jenkins_data:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock  --group-add $DOCKER_GID ${var.jenkins_ecr_repository_url}:latest
    # This parameter will be used by Lambda to confirm that this volume is backable at termination
    sleep 5
    if docker ps --format '{{.Names}}' | grep -q 'jenkins'; then
      aws ssm put-parameter --name "/jenkins/volume_id" --value "$VOLUME_ID" --type "String" --overwrite --region "${var.aws_region}"
    fi

  EOF

  tags = {
    Name      = "jenkins_master"
    Terraform = "yes"
    Volume_id = var.jenkins_volume_id
  }

}

resource "aws_volume_attachment" "jenkins_attachment" {
  device_name = "/dev/xvdf" # Adjust based on your AMI
  volume_id   = var.jenkins_volume_id
  instance_id = aws_instance.jenkins_master.id
}



locals {
  SSM_url = <<EOT
  aws ssm start-session --region ${var.aws_region} --profile personal_aws --target ${aws_instance.jenkins_master.id} --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["8080"], "localPortNumber":["8080"]}'
  EOT
}


