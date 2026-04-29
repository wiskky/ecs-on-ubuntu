# ================================
# CONFIGURATION SECTION
# ================================

# Define repository name, region, and account ID
$ECR_REPO_NAME = "nest"
$LOCAL_IMAGE_NAME = "nest"
$IMAGE_TAG = "latest"
$AWS_REGION = "eu-north-1"
$AWS_ACCOUNT_ID = "083365649738"

# ================================
# CHECK IF ECR REPOSITORY EXISTS
# ================================

# Attempt to describe the repository
aws ecr describe-repositories `
  --repository-names "${ECR_REPO_NAME}" `
  --region "${AWS_REGION}" 2>null

# $? contains True if previous command succeeded, False otherwise
$REPO_EXISTS = $?

# Check if the repository exists
if ($REPO_EXISTS) {
    Write-Host "Repository already exists. Skipping creation." -ForegroundColor Green
} else {
    Write-Host "Repository does not exist. Creating repository..." -ForegroundColor Cyan
    aws ecr create-repository `
        --repository-name "${ECR_REPO_NAME}" `
        --region "${AWS_REGION}" `
    
    # Check if repository creation was successful
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Repository created successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to create ECR repository." -ForegroundColor Red
        exit 1
    }
}

# --------------------------
# TAG AND PUSH DOCKER IMAGE
# --------------------------

# Tag the Docker image with the ECR repository URI
docker tag "${LOCAL_IMAGE_NAME}:${IMAGE_TAG}" "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}"

# Check if tagging was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "Docker image tagged successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to tag Docker image. Make sure the image '${LOCAL_IMAGE_NAME}:${IMAGE_TAG}' exists locally." -ForegroundColor Red
    Write-Host "Run 'docker images' to see available images." -ForegroundColor Yellow
    exit 1
}

# Retrieve an authentication token and log in to the ECR registry
aws ecr get-login-password --region "${AWS_REGION}" |
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Check if authentication was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully authenticated with ECR." -ForegroundColor Green
} else {
    Write-Host "Failed to authenticate with ECR." -ForegroundColor Red
    exit 1
}

# Push the Docker image to the ECR repository
docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}"

# Check if push was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "Docker image pushed successfully to ECR!" -ForegroundColor Green
    Write-Host "Image URI: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}" -ForegroundColor Cyan
} else {
    Write-Host "Docker push failed. Please check the error messages above." -ForegroundColor Red
    exit 1
}



