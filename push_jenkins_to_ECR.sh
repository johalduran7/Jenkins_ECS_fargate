#!/bin/bash
# The ECR repository must be created beforehand.
# Only CONTAINER_NAME and REPO_NAME are mandatory to run the script, AWS variables can be environmental variables
# How to run: 
# $ bash push_jenkins_to_ecr.sh CONTAINER_NAME="jenkins" REPO_NAME="jenkins_backup"
# $ bash push_jenkins_to_ecr.sh CONTAINER_NAME="jenkins" REPO_NAME="jenkins_backup" AWS_REGION="us-east-1"
# Load environment variables from script arguments if provided
for arg in "$@"; do
  eval "$arg"
done

# Ensure required variables are set (use existing ENV if not passed)
AWS_REGION=${AWS_REGION}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
CONTAINER_NAME=${CONTAINER_NAME}
REPO_NAME=${REPO_NAME}

# Validate AWS credentials and region
if [[ -z "$AWS_REGION" || -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "❌ AWS credentials or region are missing! Set them as environment variables or pass them as arguments."
  exit 1
fi

# Validate required inputs
if [[ -z "$CONTAINER_NAME" || -z "$REPO_NAME" ]]; then
  echo "Usage: bash $0 CONTAINER_NAME=\"your_container\" REPO_NAME=\"your_repo\" [AWS_REGION=\"us-east-1\"]"
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
IMAGE_NAME="${CONTAINER_NAME}_backup:latest"
docker commit "$CONTAINER_ID" "$IMAGE_NAME"
echo "✅ Committed container '$CONTAINER_NAME' as image '$IMAGE_NAME'"

# Authenticate AWS CLI
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"

# Get ECR repository URL
ECR_URL=$(aws ecr describe-repositories --query "repositories[?repositoryName=='$REPO_NAME'].repositoryUri" --output text)

if [[ -z "$ECR_URL" ]]; then
  echo "🛠️ ECR repository '$REPO_NAME' not found. Creating it..."
  aws ecr create-repository --repository-name "$REPO_NAME"
  ECR_URL=$(aws ecr describe-repositories --query "repositories[?repositoryName=='$REPO_NAME'].repositoryUri" --output text)
fi

# Authenticate Docker with ECR
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URL"

# Tag and push Docker image
docker tag "$IMAGE_NAME" "$ECR_URL:latest"
docker push "$ECR_URL:latest"

echo "✅ Successfully pushed image '$IMAGE_NAME' to '$ECR_URL'"
