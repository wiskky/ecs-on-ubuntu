# This is PowerShell script file not bash shell command

# ================================================================
# Define Docker build arguments
# ================================================================

$IMAGE_NAME="nest"
$IMAGE_TAG="latest"

$GITHUB_USERNAME="wiskky"
$REPOSITORY_NAME="nest-app-zip-file"
$APPLICATION_CODE_FILE_NAME="nest"`

$RDS_ENDPOINT="dev-nest-db.cnyooq6s698t.eu-north-1.rds.amazonaws.coms"
$RDS_DB_NAME="applicationdb"
$RDS_DB_USERNAME="admin"

$DOMAIN_NAME="www.tekworld.name.ng"

$SECRET_NAME="dev-nest-secret"
$AWS_REGION="eu-north-1"

# ================================================================
# Retrieve secrets from AWS Secrets Manager
# ================================================================

echo  "Starting Docker build process for $IMAGE_NAME application..."
echo "Retrieving secrets from AWS Secrets Manager..." 

# Retrieve secret from Secrets Manager
$SECRET_JSON = aws secretsmanager get-secret-value `
    --secret-id $SECRET_NAME `
    --region $AWS_REGION `
    --query SecretString `
    --output text

# Check if secret retrieval was successful
if ($LASTEXITCODE -ne 0) {
    echo "Error: Failed to retrieve secrets from AWS Secrets Manager" 
    exit 1
}

# Parse the JSON secret and validate
try {
    $SECRET = $SECRET_JSON | ConvertFrom-Json

    # Sensitive values (will be used as BuildKit secrets)
    $PERSONAL_ACCESS_TOKEN = $SECRET.personal_access_token
    $RDS_DB_PASSWORD = $SECRET.password

    # Validate secrets were parsed correctly
    if ([string]::IsNullOrEmpty($PERSONAL_ACCESS_TOKEN) -or [string]::IsNullOrEmpty($RDS_DB_PASSWORD)) {
        throw "Failed to parse secrets from JSON"
    }

    echo "Secrets retrieved successfully!" 
}
catch {
    echo "Error: Failed to parse secrets from JSON" 
    exit 1
}

# ============================================================
# BUILD DOCKER IMAGE WITH BUILDKIT SECRETS
# ============================================================

echo "Building Docker image with BuildKit secrets..." 

# Enable BuildKit
$env:DOCKER_BUILDKIT = 1

# Set secrets as environment variables for BuildKit (will be mounted as secrets in the container)
$env:PERSONAL_ACCESS_TOKEN_SECRET = $PERSONAL_ACCESS_TOKEN
$env:RDS_DB_PASSWORD_SECRET = $RDS_DB_PASSWORD

# Run the docker build command with BuildKit secrets
docker build `
  --secret id=personal_access_token,env=PERSONAL_ACCESS_TOKEN_SECRET `
  --secret id=rds_db_password,env=RDS_DB_PASSWORD_SECRET `
  --build-arg GITHUB_USERNAME="$GITHUB_USERNAME" `
  --build-arg REPOSITORY_NAME="$REPOSITORY_NAME" `
  --build-arg APPLICATION_CODE_FILE_NAME="$APPLICATION_CODE_FILE_NAME" `
  --build-arg RDS_ENDPOINT="$RDS_ENDPOINT" `
  --build-arg RDS_DB_NAME="$RDS_DB_NAME" `
  --build-arg RDS_DB_USERNAME="$RDS_DB_USERNAME" `
  --build-arg DOMAIN_NAME="$DOMAIN_NAME" `
  -t "${IMAGE_NAME}:${IMAGE_TAG}" `
  .

# Clean up temporary environment variables
unset PERSONAL_ACCESS_TOKEN_SECRET 
unset Env:\RDS_DB_PASSWORD_SECRET 

# Check if build was successful
if ($LASTEXITCODE -eq 0) {

   echo  "Docker image $IMAGE_NAME built successfully!" -ForegroundColor Green
}
else {
    Write-Host "Docker build failed. Please check the error messages above." -ForegroundColor Red
    exit 1
}


# SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $AWS_REGION --query SecretString --output text)
# PERSONAL_ACCESS_TOKEN=$(echo $SECRET_JSON | jq -r '.personal_access_token')
# RDS_DB_PASSWORD=$(echo $SECRET_JSON | jq -r '.password')

# # ================================================================
# # Enable BuildKit and set secrets
# # ================================================================

# export DOCKER_BUILDKIT=1
# export PERSONAL_ACCESS_TOKEN_SECRET=$PERSONAL_ACCESS_TOKEN
# export RDS_DB_PASSWORD_SECRET=$RDS_DB_PASSWORD

# # ================================================================
# # Build Docker image
# # ================================================================

# docker build \
#     --secret id=personal_access_token,env=PERSONAL_ACCESS_TOKEN_SECRET \
#     --secret id=rds_db_password,env=RDS_DB_PASSWORD_SECRET \
#     --build-arg DOMAIN_NAME="$DOMAIN_NAME" \
#     --build-arg GITHUB_USERNAME="$GITHUB_USERNAME" \
#     --build-arg REPOSITORY_NAME="$REPOSITORY_NAME" \
#     --build-arg APPLICATION_CODE_FILE_NAME="$APPLICATION_CODE_FILE_NAME" \
#     --build-arg RDS_ENDPOINT="$RDS_ENDPOINT" \
#     --build-arg RDS_DB_NAME="$RDS_DB_NAME" \
#     --build-arg RDS_DB_USERNAME="$RDS_DB_USERNAME" \
#     -t "${IMAGE_NAME}:${IMAGE_TAG}" \
#     .

# # ================================================================
# # Cleanup
# # ================================================================

# unset PERSONAL_ACCESS_TOKEN_SECRET RDS_DB_PASSWORD_SECRET
