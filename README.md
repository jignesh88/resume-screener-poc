# AWS Resume Screener System

A complete serverless solution for job listing, application collection, resume screening, phone interviewing, and interview scheduling using AWS services.

## Architecture Overview

This project implements an end-to-end resume screening and interview system using serverless AWS services:

1. **Frontend**: Next.js web application hosted on S3 and CloudFront
2. **Backend**: API Gateway and Lambda functions for job listings and applications
3. **Resume Processing**: S3, Lambda, Textract, and Bedrock for intelligent resume screening
4. **Phone Interviews**: Amazon Connect for automated phone screening
5. **Interview Scheduling**: Email notifications via SES or Gmail integration

## Repository Structure

```
/
├── main.tf                 # Main Terraform resources
├── variables.tf            # Input variables definition
├── outputs.tf              # Output values
├── s3_notification.tf      # S3 event triggers
├── step_function.tf        # Step Functions workflow
├── api_gateway.tf          # API Gateway configuration
├── frontend_infra.tf       # S3 and CloudFront for frontend
├── frontend/               # Next.js application
├── backend/                # Lambda functions for API
│   └── lambda/
│       └── api/
│           ├── jobs.py     # API for job listings
│           └── applications.py # API for applications
├── lambda/                 # Lambda functions for processing
│   ├── extract_text/       # Text extraction from resumes
│   ├── screen_resume/      # Resume screening with AI
│   ├── rank_candidates/    # Candidate ranking
│   ├── phone_interview/    # Phone interview management
│   └── schedule_interview/ # Interview scheduling
├── deploy_frontend.sh      # Frontend deployment script
└── setup_job_data.sh       # Sample data initialization
```

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Terraform v1.0.0+ installed
- Node.js 16+ and npm for frontend development
- Python 3.9+ for Lambda functions

## Deployment Instructions

### 1. Set Up AWS Infrastructure

```bash
# Initialize Terraform
terraform init

# Apply Terraform configuration
terraform apply -var-file=terraform.tfvars

# Save Terraform outputs for deployment scripts
terraform output -json > terraform_output.json
```

### 2. Create Sample Job Data

```bash
# Make the script executable
chmod +x setup_job_data.sh

# Run the script to create sample job data
./setup_job_data.sh
```

### 3. Deploy the Frontend

```bash
# Make the script executable
chmod +x deploy_frontend.sh

# Build and deploy the frontend to S3/CloudFront
./deploy_frontend.sh
```

### 4. Manual Setup Steps

Some components require manual setup through the AWS Console:

1. **Amazon Connect**: Set up an instance and contact flow as described in the main README.md
2. **Amazon Bedrock**: Configure a Knowledge Base for enhanced resume analysis

## Testing the System

1. **Browse Jobs**: Visit the CloudFront URL to browse available jobs
2. **Submit Application**: Apply for a job with your resume
3. **Check Status**: Monitor the application status
4. **Receive Call**: If selected as a top candidate, receive a phone interview
5. **Schedule Interview**: For successful candidates, an interview will be scheduled

## Development

### Frontend Development

```bash
# Install dependencies
cd frontend
npm install

# Run development server
npm run dev
```

### Lambda Function Testing

```bash
# Test a Lambda function locally
python -m lambda.extract_text.extract_text
```

## License

MIT
