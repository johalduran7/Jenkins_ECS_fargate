#!/bin/bash
# The SR Bucket must be created beforehand.
# Only SR_BUCKET and REPO_NAME are mandatory to run the script, AWS variables can be environmental variables
# How to run: bash backup_jenkins_volume.sh JENKINS_VOLUME="jenkins_home" S3_BUCKET="my-jenkins-backups"

# Load environment variables from script arguments if provided
for arg in "$@"; do
  eval "$arg"
done

# Ensure required variables are set (use existing ENV if not passed)
AWS_REGION=${AWS_REGION}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
JENKINS_VOLUME=${JENKINS_VOLUME}
S3_BUCKET=${S3_BUCKET}

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

# Authenticate AWS CLI
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"

# Upload backup to S3
aws s3 cp "$TMP_DIR/$BACKUP_FILE" "s3://$S3_BUCKET/$BACKUP_FILE"

if [[ $? -ne 0 ]]; then
  echo "❌ Failed to upload backup to S3!"
  exit 1
fi

echo "✅ Backup successfully uploaded to s3://$S3_BUCKET/$BACKUP_FILE"

# Clean up temporary files
rm -rf "$TMP_DIR"
echo "🧹 Cleaned up temporary files."

