#!/bin/bash

# Deploy the Next.js frontend to S3 and invalidate CloudFront cache

set -e

# Check if required variables are set
TERRAFORM_OUTPUT_FILE="terraform_output.json"
if [ ! -f "$TERRAFORM_OUTPUT_FILE" ]; then
  echo "Terraform output file not found. Generating it..."
  terraform output -json > "$TERRAFORM_OUTPUT_FILE"
fi

# Extract values from Terraform output
FRONTEND_BUCKET_NAME=$(cat "$TERRAFORM_OUTPUT_FILE" | jq -r '.frontend_bucket_name.value')
CLOUDFRONT_DISTRIBUTION_ID=$(cat "$TERRAFORM_OUTPUT_FILE" | jq -r '.frontend_cloudfront_dist_id.value')
API_URL=$(cat "$TERRAFORM_OUTPUT_FILE" | jq -r '.api_gateway_url.value')

if [ -z "$FRONTEND_BUCKET_NAME" ] || [ "$FRONTEND_BUCKET_NAME" == "null" ]; then
  echo "Error: Frontend bucket name not found in Terraform output"
  exit 1
fi

if [ -z "$CLOUDFRONT_DISTRIBUTION_ID" ] || [ "$CLOUDFRONT_DISTRIBUTION_ID" == "null" ]; then
  echo "Error: CloudFront distribution ID not found in Terraform output"
  exit 1
fi

if [ -z "$API_URL" ] || [ "$API_URL" == "null" ]; then
  echo "Error: API Gateway URL not found in Terraform output"
  exit 1
fi

echo "API Gateway URL: $API_URL"

# Set API URL in environment file
echo "Creating .env.production file with API URL: $API_URL"
cat > frontend/.env.production << EOL
NEXT_PUBLIC_API_URL=$API_URL
EOL

# Build the Next.js app
echo "Building Next.js app..."
cd frontend
npm ci
npm run build

# Deploy to S3
echo "Deploying to S3 bucket: $FRONTEND_BUCKET_NAME"
aws s3 sync out/ "s3://$FRONTEND_BUCKET_NAME" --delete

# Invalidate CloudFront cache
echo "Invalidating CloudFront cache: $CLOUDFRONT_DISTRIBUTION_ID"
aws cloudfront create-invalidation --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" --paths "/*"

echo "Frontend deployment completed successfully!"
cd ..
