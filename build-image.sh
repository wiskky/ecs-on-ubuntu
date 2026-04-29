#!/usr/bin/env bash

set -euo pipefail

# ================================================================
# CONFIGURATION
# ================================================================

IMAGE_NAME="nest"
IMAGE_TAG="latest"

GITHUB_USERNAME="wiskky"
REPOSITORY_NAME="nest-app-zip-file"
APPLICATION_CODE_FILE_NAME="nest"

RDS_ENDPOINT="dev-nest-db.cnyooq6s698t.eu-north-1.rds.amazonaws.com"
RDS_DB_NAME="applicationdb"
RDS_DB_USERNAME="admin"

DOMAIN_NAME="tekworld.name.ng"
RECORD_NAME="www"

PROJECT_NAME="nest-app"
ENVIRONMENT="dev"

SECRET_NAME="dev-app-secret"
AWS_REGION="eu-north-1"

# ================================================================
# VALIDATE DEPENDENCIES
# ================================================================

command -v aws >/dev/null || { echo "aws CLI not installed"; exit 1; }
command -v docker >/dev/null || { echo "docker not installed"; exit 1; }
command -v jq >/dev/null || { echo "jq not installed"; exit 1; }

# ================================================================
# FETCH SECRETS
# ================================================================

echo "Retrieving secrets from AWS..."

SECRET_JSON=$(aws secretsmanager get-secret-value \
--secret-id "$SECRET_NAME" \
--region "$AWS_REGION" \
--query SecretString \
--output text)

export PERSONAL_ACCESS_TOKEN=$(echo "$SECRET_JSON" | jq -r '.personal_access_token')
export RDS_DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')

if [[ -z "$PERSONAL_ACCESS_TOKEN" || -z "$RDS_DB_PASSWORD" ]]; then
  echo "Failed to parse secrets"
  exit 1
fi

echo "Secrets retrieved"

# ================================================================
# ENABLE BUILDKIT
# ================================================================

export DOCKER_BUILDKIT=1

# ================================================================
# BUILD DOCKER IMAGE
# ================================================================

echo "Building Docker image..."

docker build \
  --secret id=personal_access_token,env=PERSONAL_ACCESS_TOKEN \
  --secret id=rds_db_password,env=RDS_DB_PASSWORD \
  --build-arg GITHUB_USERNAME="$GITHUB_USERNAME" \
  --build-arg REPOSITORY_NAME="$REPOSITORY_NAME" \
  --build-arg APPLICATION_CODE_FILE_NAME="$APPLICATION_CODE_FILE_NAME" \
  --build-arg RDS_ENDPOINT="$RDS_ENDPOINT" \
  --build-arg RDS_DB_NAME="$RDS_DB_NAME" \
  --build-arg RDS_DB_USERNAME="$RDS_DB_USERNAME" \
  --build-arg DOMAIN_NAME="$DOMAIN_NAME" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  .

echo " Docker image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"


