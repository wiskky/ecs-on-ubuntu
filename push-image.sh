
#!/usr/bin/env bash

set -euo pipefail

# ================================================================
# CONFIGURATION
# ================================================================

ECR_REPO_NAME="nest"
LOCAL_IMAGE_NAME="nest"
IMAGE_TAG="latest"
AWS_REGION="eu-north-1"
AWS_ACCOUNT_ID="083365649738"

ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULL_IMAGE_NAME="${ECR_URI}/${ECR_REPO_NAME}:${IMAGE_TAG}"

# ================================================================
# VALIDATE DEPENDENCIES
# ================================================================

command -v aws >/dev/null || { echo "aws CLI not installed"; exit 1; }
command -v docker >/dev/null || { echo "docker not installed"; exit 1; }

# ================================================================
# CHECK IF IMAGE EXISTS LOCALLY
# ================================================================

if ! docker image inspect "${LOCAL_IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
  echo "Local image ${LOCAL_IMAGE_NAME}:${IMAGE_TAG} not found"
  echo "Run your build script first"
  exit 1
fi

echo "Local Docker image found"

# ================================================================
# CHECK / CREATE ECR REPOSITORY
# ================================================================

echo "Checking if ECR repository exists..."

if aws ecr describe-repositories \
    --repository-names "${ECR_REPO_NAME}" \
    --region "${AWS_REGION}" >/dev/null 2>&1; then

  echo "Repository already exists"

else
  echo "Creating ECR repository..."

  aws ecr create-repository \
    --repository-name "${ECR_REPO_NAME}" \
    --region "${AWS_REGION}" >/dev/null

  echo "Repository created"
fi

# ================================================================
# LOGIN TO ECR
# ================================================================

echo "Logging into ECR..."

aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login \
      --username AWS \
      --password-stdin "${ECR_URI}"

echo "Authenticated with ECR"

# ================================================================
# TAG IMAGE
# ================================================================

echo "Tagging Docker image..."

docker tag "${LOCAL_IMAGE_NAME}:${IMAGE_TAG}" "${FULL_IMAGE_NAME}"

echo "Image tagged: ${FULL_IMAGE_NAME}"

# ================================================================
# PUSH IMAGE
# ================================================================

echo "Pushing image to ECR..."

docker push "${FULL_IMAGE_NAME}"

echo "Push successful!"
echo "Image URI: ${FULL_IMAGE_NAME}"

