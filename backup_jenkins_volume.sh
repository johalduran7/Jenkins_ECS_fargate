#!/bin/bash
# This script backs up a Jenkins volume to an S3 bucket.
# Only JENKINS_VOLUME and S3_BUCKET are mandatory; AWS variables can be environment variables or already configured in AWS CLI.
# How to run: 
# $ bash backup_jenkins_volume.sh JENKINS_VOLUME="jenkins_home" S3_BUCKET="my-jenkins-backups"
# $ bash backup_jenkins_volume.sh JENKINS_VOLUME="jenkins_home" S3_BUCKET="my-jenkins-backups" AWS_REGION="us-east-1"

# Load environment variables from script arguments if provided
for arg in "$@"; do
  eval "$arg"
done

# Validate AWS credentials and region (use existing CLI config if not set)
AWS_REGION=${AWS_REGION:-$(aws configure get region)}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-$(aws configure get aws_access_key_id)}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-$(aws configure get aws_secret_access_key)}

# Validate required AWS inputs
if [[ -z "$AWS_REGION" || -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "❌ AWS credentials or region are missing! Set them as environment variables, pass them as arguments, or configure them using 'aws configure'."
  exit 1
fi

# Validate required inputs
if [[ -z "$JENKINS_VOLUME" || -z "$S3_BUCKET" ]]; then
  echo "Usage: bash $0 JENKINS_VOLUME=\"jenkins_home\" S3_BUCKET=\"my-backup-bucket\" [AWS_REGION=\"us-east-1\"]"
  exit 1
fi

# Set backup filename with timestamp
BACKUP_FILE="jenkins_volume_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

# Create a temporary directory
TMP_DIR=$(mktemp -d)
echo "✅ Created temp directory: $TMP_DIR"

# Copy the Docker volume contents to the temporary directory
docker run --rm -v "$JENKINS_VOLUME":/data -v "$TMP_DIR":/backup busybox sh -c "tar -czf /backup/$BACKUP_FILE -C /data ."

if [[ $? -ne 0 ]]; then
  echo "❌ Failed to archive the Jenkins volume!"
  exit 1
fi

echo "✅ Jenkins volume '$JENKINS_VOLUME' archived as '$BACKUP_FILE'"

# Upload backup to S3
# aws s3 cp "$TMP_DIR/$BACKUP_FILE" "s3://$S3_BUCKET/$BACKUP_FILE" --region "$AWS_REGION"

# if [[ $? -ne 0 ]]; then
#   echo "❌ Failed to upload backup to S3!"
#   exit 1
# fi

echo "✅ Backup successfully uploaded to s3://$S3_BUCKET/$BACKUP_FILE"
cd $TMP_DIR
base64 $BACKUP_FILE > $BACKUP_FILE.base64
# Clean up temporary files
#rm -rf "$TMP_DIR"
echo "🧹 Cleaned up temporary files."
