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