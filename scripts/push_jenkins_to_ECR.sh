#!/bin/bash
# The ECR repository must be created beforehand.
# Only CONTAINER_NAME and REPO_NAME are mandatory to run the script.
# AWS credentials will be checked in the environment or AWS CLI config.

# How to run: 
# $ bash push_jenkins_to_ecr.sh CONTAINER_NAME="jenkins" REPO_NAME="jenkins"
# $ bash push_jenkins_to_ecr.sh CONTAINER_NAME="jenkins" REPO_NAME="jenkins" AWS_REGION="us-east-1"

# If you don't have a local Jenkins installed, just install the container in jenkins_master. 
# docker built -t jenkins .
# then run: docker run -t -d --name jenkins jenkins

# Load environment variables from script arguments if provided
for arg in "$@"; do
  eval "$arg"
done

# Ensure required variables are set (use existing ENV if not passed)
AWS_REGION=${AWS_REGION:-"us-east-1"}
CONTAINER_NAME=${CONTAINER_NAME}
REPO_NAME=${REPO_NAME}

# Validate required inputs
if [[ -z "$CONTAINER_NAME" || -z "$REPO_NAME" ]]; then
  echo "❌ Usage: bash $0 CONTAINER_NAME=\"your_container\" REPO_NAME=\"your_repo\" [AWS_REGION=\"us-east-1\"]"
  exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo "❌ AWS CLI is not installed! Please install it before running this script."
  exit 1
fi

# Validate AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
  echo "❌ AWS credentials are not configured! Please run 'aws configure' or set AWS environment variables."
  exit 1
fi

# Find the container ID using the provided container name
CONTAINER_ID=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.ID}}")

if [[ -z "$CONTAINER_ID" ]]; then
  echo "❌ No running container found with name '$CONTAINER_NAME'"
  exit 1
fi

echo "✅ Found container '$CONTAINER_NAME' (ID: $CONTAINER_ID)"

# Commit the running container to a new image
IMAGE_NAME="${CONTAINER_NAME}:latest"
docker commit "$CONTAINER_ID" "$IMAGE_NAME"
echo "✅ Committed container '$CONTAINER_NAME' as image '$IMAGE_NAME'"

# Get ECR repository URL
ECR_URL=$(aws ecr describe-repositories --query "repositories[?repositoryName=='$REPO_NAME'].repositoryUri" --output text)

if [[ -z "$ECR_URL" ]]; then
  echo "🛠️ ECR repository '$REPO_NAME' not found."
  exit 1
fi
echo "AWS_REGION: " $AWS_REGION
# Authenticate Docker with ECR
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URL"

# Tag and push Docker image
docker tag "$IMAGE_NAME" "$ECR_URL:latest"
docker push "$ECR_URL:latest"

echo "✅ Successfully pushed image '$IMAGE_NAME' to '$ECR_URL'"
