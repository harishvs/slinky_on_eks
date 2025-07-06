#!/bin/bash
set -e

# Configuration
BUCKET_NAME="eks-slinky-terraform-state"
DYNAMODB_TABLE="eks-slinky-terraform-locks"
REGION="us-east-1"

echo "Setting up Terraform backend infrastructure..."

# Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME"
if [ "$REGION" = "us-east-1" ]; then
    # us-east-1 is the default region and doesn't need LocationConstraint
    aws s3api create-bucket \
        --bucket $BUCKET_NAME \
        --region $REGION \
        --no-cli-pager
else
    # Other regions need LocationConstraint
    aws s3api create-bucket \
        --bucket $BUCKET_NAME \
        --region $REGION \
        --create-bucket-configuration LocationConstraint=$REGION \
        --no-cli-pager
fi

# Enable versioning on the bucket
echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled \
    --no-cli-pager

# Enable server-side encryption
echo "Enabling server-side encryption..."
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }' \
    --no-cli-pager

# Block public access
echo "Blocking public access..."
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
    --no-cli-pager

# Create DynamoDB table for state locking
echo "Creating DynamoDB table: $DYNAMODB_TABLE"
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION \
    --no-cli-pager

# Wait for DynamoDB table to be active
echo "Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists \
    --table-name $DYNAMODB_TABLE \
    --region $REGION \
    --no-cli-pager

echo "Backend infrastructure setup complete!"
echo ""
echo "Next steps:"
echo "1. Run: terraform init"
echo "2. Run: terraform plan"
echo "3. Run: terraform apply"
echo ""
echo "Note: Make sure you have AWS CLI configured with appropriate permissions." 