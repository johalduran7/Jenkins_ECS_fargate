#!/bin/bash
# This script backs up a Jenkins volume to an EBS volume.
# Only JENKINS_VOLUME and BACKUP_DIR are mandatory.
# How to run:
# $ bash backup_jenkins_volume.sh JENKINS_VOLUME="jenkins_home" BACKUP_DIR="/mnt/jenkins_backups"

# Load environment variables from script arguments if provided
for arg in "$@"; do
  eval "$arg"
done

# Validate required inputs
if [[ -z "$JENKINS_VOLUME" || -z "$BACKUP_DIR" ]]; then
  echo "❌ Usage: bash $0 JENKINS_VOLUME=\"jenkins_home\" BACKUP_DIR=\"/mnt/jenkins_backups\""
  exit 1
fi

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Set backup filename with timestamp
BACKUP_FILE="jenkins_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

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

# Move backup to EBS volume
mv "$TMP_DIR/$BACKUP_FILE" "$BACKUP_DIR"

if [[ $? -ne 0 ]]; then
  echo "❌ Failed to move backup to EBS volume!"
  exit 1
fi

echo "✅ Backup successfully stored on EBS at '$BACKUP_DIR/$BACKUP_FILE'"

# Clean up temporary files
rm -rf "$TMP_DIR"
echo "🧹 Cleaned up temporary files."
