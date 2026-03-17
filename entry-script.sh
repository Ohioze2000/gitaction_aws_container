#!/bin/bash

# 1. Exit immediately if any command fails
set -e

# 2. Check if Docker is running
if ! command -v docker &> /dev/null; then
    echo "❌ ERROR: Docker is not installed or not in your PATH."
    exit 1
fi

# 3. Variables - Fetching directly from Terraform Outputs
echo "🔍 Fetching infrastructure details from Terraform..."

REGION="us-east-1"
REPO_URL=$(terraform output -raw ecr_repository_url)
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)
IMAGE_TAG="latest"

# 4. Safety Check: Ensure Terraform outputs aren't empty
if [ -z "$REPO_URL" ] || [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
    echo "❌ ERROR: Could not fetch all required outputs from Terraform."
    echo "Ensure you have defined 'ecr_repository_url', 'ecs_cluster_name', and 'ecs_service_name' in your root outputs.tf"
    exit 1
fi

# 5. Authenticate Docker with AWS ECR
echo "🔐 Authenticating with ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URL

# 6. Build the Docker Image
# We use './app' as the context because that's where your Dockerfile lives.
echo "🏗️  Building Docker image from ./app folder..."
docker build --platform linux/amd64 -t my-website-app ./app

# 7. Tag the Image for ECR
echo "🏷️  Tagging image..."
docker tag my-website-app:latest $REPO_URL:$IMAGE_TAG

# 8. Push to ECR
echo "🚀 Pushing image to AWS ECR..."
docker push $REPO_URL:$IMAGE_TAG

# 9. Force ECS to pull the new image
echo "♻️  Force-restarting ECS service to deploy new code..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment --region $REGION

# 10. Wait for stabilization (OPTIONAL AMENDMENT)
echo "⏳ Waiting for service to reach steady state..."
aws ecs wait services-stable --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION

echo "----------------------------------------------------------"
echo "✅ DEPLOYMENT COMPLETE!"
echo "Your website is updating at: $REPO_URL"
echo "----------------------------------------------------------"