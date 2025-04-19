# AWS Phone-Based Chatbot for Candidate Screening and Interview Scheduling

This Terraform project deploys a complete AWS serverless architecture for an automated phone-based chatbot system that screens job candidates, conducts initial phone interviews, and schedules in-person interviews with hiring managers and technical staff.

## Architecture Overview

The system uses the following AWS services:

1. **Amazon Connect**: Handles telephony via a toll-free mobile number
2. **Amazon Bedrock with Amazon Nova Sonic**: Processes speech and generative AI with Retrieval-Augmented Generation
3. **Amazon OpenSearch Service**: Stores vector embeddings for RAG
4. **Amazon S3**: Stores PDFs and resume documents
5. **Amazon Textract**: Extracts text from PDFs and word documents
6. **AWS Lambda**: Processes queries and tool calls in Python
7. **Amazon DynamoDB**: Stores candidate data and rankings
8. **Amazon CloudWatch**: Monitors metrics and logs
9. **AWS Step Functions**: Orchestrates Lambda functions in the workflow
10. **Amazon SES**: Sends email notifications for interview scheduling (simulates Gmail integration)

## Workflow

1. Resumes are uploaded to an S3 bucket
2. AWS Step Functions orchestrates the end-to-end process:
   - Extract text from resumes using Textract
   - Screen resumes using Bedrock (Claude 3 Sonnet)
   - Rank candidates and identify top 5%
   - Conduct phone interviews with top candidates using Amazon Connect
   - Schedule in-person interviews for successful candidates

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Terraform v1.0.0+ installed
- Python 3.9+ installed
- An Amazon Connect instance (created manually)
- Verified email addresses in Amazon SES (for sending emails)
- AWS Secrets Manager secret for Gmail credentials (if using actual Gmail integration)

## Deployment

### Step 1: Configure Variables

Create a `terraform.tfvars` file with the required variables:

```hcl
aws_region                = "ap-southeast-2"
resume_bucket_name        = "your-resume-bucket-name" 
opensearch_domain_name    = "your-opensearch-domain"
opensearch_master_user    = "admin"
opensearch_master_password = "StrongPassword123!"
connect_instance_id       = "your-connect-instance-id"
connect_contact_flow_id   = "your-connect-flow-id"
gmail_credentials_secret_arn = "arn:aws:secretsmanager:region:account:secret:gmail-credentials"
hiring_manager_email      = "hiring_manager@example.com"
technical_staff_email     = "tech_staff@example.com"
company_name              = "Your Company Name"
company_phone             = "+61123456789"
```

### Step 2: Initialize and Apply Terraform

```bash
# Initialize Terraform
terraform init

# Validate the configuration
terraform validate

# Review the execution plan
terraform plan -var-file=terraform.tfvars

# Apply the configuration
terraform apply -var-file=terraform.tfvars
```

### Step 3: Manual Setup for Amazon Connect

Since Terraform has limited support for Amazon Connect configuration, follow these steps to set up your Amazon Connect instance:

1. **Create an Amazon Connect instance** (if not already created):
   - Go to the Amazon Connect console
   - Click "Add an instance"
   - Follow the prompts to create a new instance

2. **Claim a phone number**:
   - In your Amazon Connect instance, go to "Channels" > "Phone numbers"
   - Click "Claim a number"
   - Select your country and a toll-free number
   - Assign it to your contact flow (created in the next step)

3. **Create a contact flow**:
   - In your Amazon Connect instance, go to "Routing" > "Contact flows"
   - Click "Create contact flow"
   - Create a flow with the following blocks:
     - Start: Entry point
     - Get customer input: Voice prompt using the script from Lambda
     - Invoke AWS Lambda function: Call the PhoneInterview Lambda
     - Set contact attributes: Store the Lambda response
     - Play prompt: Respond to the candidate based on Lambda results
     - Disconnect: End the call
   - Save and publish the flow
   - Note the contact flow ID for your `terraform.tfvars` file

### Step 4: Manual Setup for Amazon Bedrock Knowledge Base

To set up the Knowledge Base for RAG capabilities:

1. **Create a Knowledge Base**:
   - Go to Amazon Bedrock console
   - Navigate to "Knowledge bases"
   - Click "Create knowledge base"
   - Select OpenSearch as your vector store
   - Choose the OpenSearch domain created by Terraform
   - Select the S3 bucket created by Terraform as your data source
   - Configure sync settings to automatically process new resumes
   - Complete the Knowledge Base setup

2. **Update Lambda environment variables** with your Knowledge Base ID:
   - Go to the Lambda console
   - Select the ScreenResume function
   - Add the Knowledge Base ID to environment variables

## Usage

### Resume Ingestion

1. Upload resumes to the S3 bucket following this structure:
   - `s3://your-resume-bucket/resumes/{job_id}/{candidate_id}.pdf`
   - For example: `s3://your-resume-bucket/resumes/software-engineer/candidate123.pdf`

2. The S3 event will trigger the Step Functions workflow automatically.

### Monitoring

- Use CloudWatch Logs to monitor each Lambda function's execution
- Use CloudWatch Metrics to track key performance indicators
- View the Step Functions execution console to track the progress of each candidate

### Testing

1. **Test resume extraction**:
   ```bash
   aws lambda invoke --function-name ExtractTextFromResume --payload '{"Records":[{"eventSource":"aws:s3","s3":{"bucket":{"name":"your-resume-bucket"},"object":{"key":"resumes/software-engineer/test-candidate.pdf"}}}]}' output.json
   ```

2. **Test the entire workflow**:
   ```bash
   aws stepfunctions start-execution --state-machine-arn <state-machine-arn> --input '{"candidateId":"test-candidate", "jobId":"software-engineer"}'
   ```

## Customization

### Job Descriptions

Edit the `get_job_description` function in `screen_resume.py` to add or modify job descriptions.

### Evaluation Criteria

Modify the prompts in `screen_resume.py` to adjust how candidates are evaluated.

### Interview Questions

Customize the interview script generation in `phone_interview.py` to ask different questions.

## Cleanup

To remove all resources created by this Terraform project:

```bash
terraform destroy -var-file=terraform.tfvars
```

**Note**: This will not delete resources created manually, such as the Amazon Connect instance. Those must be deleted through the AWS Console.

## Security Considerations

- This deployment uses encryption for data at rest and in transit
- IAM roles follow the principle of least privilege
- Consider implementing additional security measures such as:
  - VPC for OpenSearch
  - AWS WAF for protection against malicious requests
  - AWS KMS for enhanced encryption

## Limitations

- Amazon Connect setup requires manual configuration
- Bedrock Knowledge Base setup requires manual configuration
- Email sending uses Amazon SES instead of direct Gmail integration
- This implementation simulates some aspects of the workflow for demonstration purposes