#!/bin/bash

# Create sample job data in DynamoDB

set -e

# Check if required variables are set
TERRAFORM_OUTPUT_FILE="terraform_output.json"
if [ ! -f "$TERRAFORM_OUTPUT_FILE" ]; then
  echo "Terraform output file not found. Generating it..."
  terraform output -json > "$TERRAFORM_OUTPUT_FILE"
fi

# Extract DynamoDB table name from Terraform output
JOB_TABLE_NAME=$(cat "$TERRAFORM_OUTPUT_FILE" | jq -r '.dynamodb_table_name.value')

if [ -z "$JOB_TABLE_NAME" ] || [ "$JOB_TABLE_NAME" == "null" ]; then
  # Use the default value from variables.tf
  JOB_TABLE_NAME="Jobs"
  echo "Warning: Job table name not found in Terraform output, using default: $JOB_TABLE_NAME"
fi

echo "Creating sample job data in DynamoDB table: $JOB_TABLE_NAME"

# Sample job data - Software Engineer
aws dynamodb put-item \
  --table-name "$JOB_TABLE_NAME" \
  --item '{
    "id": {"S": "software-engineer-001"},
    "title": {"S": "Senior Software Engineer"},
    "category": {"S": "Engineering"},
    "location": {"S": "Sydney, Australia"},
    "job_type": {"S": "Full-time"},
    "salary_range": {"S": "$120,000 - $150,000"},
    "short_description": {"S": "Join our engineering team to build innovative cloud solutions using AWS services."},
    "description": {"S": "We are looking for a Senior Software Engineer to join our growing team. You will design, develop, and maintain our cloud-based applications, working with a modern tech stack including AWS, TypeScript, and React."},
    "responsibilities": {"L": [
      {"S": "Design and develop scalable, high-performance applications"}, 
      {"S": "Collaborate with cross-functional teams to define features"}, 
      {"S": "Write clean, maintainable code with comprehensive test coverage"}, 
      {"S": "Review code and mentor junior developers"}, 
      {"S": "Troubleshoot and debug complex technical issues"}
    ]},
    "requirements": {"L": [
      {"S": "5+ years of software development experience"},
      {"S": "Strong knowledge of AWS services"}, 
      {"S": "Experience with modern JavaScript frameworks"}, 
      {"S": "Background in distributed systems"}, 
      {"S": "CI/CD pipeline experience"}
    ]},
    "benefits": {"L": [
      {"S": "Competitive salary and equity package"},
      {"S": "Flexible working arrangements"},
      {"S": "Professional development budget"},
      {"S": "Health insurance"}
    ]},
    "posted_date": {"S": "2025-04-10T00:00:00Z"},
    "closing_date": {"S": "2025-05-10T00:00:00Z"},
    "status": {"S": "OPEN"}
  }'

# Sample job data - Data Scientist
aws dynamodb put-item \
  --table-name "$JOB_TABLE_NAME" \
  --item '{
    "id": {"S": "data-scientist-001"},
    "title": {"S": "Senior Data Scientist"},
    "category": {"S": "Data Science"},
    "location": {"S": "Melbourne, Australia"},
    "job_type": {"S": "Full-time"},
    "salary_range": {"S": "$130,000 - $160,000"},
    "short_description": {"S": "Lead data science initiatives using advanced ML models and AWS Bedrock."},
    "description": {"S": "We are seeking a Senior Data Scientist to drive our machine learning and AI initiatives. You will work with large datasets to build predictive models and derive actionable insights that drive business value."},
    "responsibilities": {"L": [
      {"S": "Develop and implement ML/AI models"}, 
      {"S": "Analyze complex datasets to extract insights"}, 
      {"S": "Work with engineering teams to implement models in production"}, 
      {"S": "Present findings to business stakeholders"}, 
      {"S": "Stay current with latest AI research and techniques"}
    ]},
    "requirements": {"L": [
      {"S": "Master's or PhD in Computer Science, Statistics, or related field"},
      {"S": "4+ years of experience in applied data science"}, 
      {"S": "Strong Python programming skills"}, 
      {"S": "Experience with ML frameworks like TensorFlow or PyTorch"}, 
      {"S": "Background in NLP and generative AI is a plus"}
    ]},
    "benefits": {"L": [
      {"S": "Competitive salary and equity package"},
      {"S": "Flexible working arrangements"},
      {"S": "Conference and training budget"},
      {"S": "Health insurance"}
    ]},
    "posted_date": {"S": "2025-04-12T00:00:00Z"},
    "closing_date": {"S": "2025-05-12T00:00:00Z"},
    "status": {"S": "OPEN"}
  }'

# Sample job data - DevOps Engineer
aws dynamodb put-item \
  --table-name "$JOB_TABLE_NAME" \
  --item '{
    "id": {"S": "devops-engineer-001"},
    "title": {"S": "DevOps Engineer"},
    "category": {"S": "Operations"},
    "location": {"S": "Remote, Australia"},
    "job_type": {"S": "Full-time"},
    "salary_range": {"S": "$115,000 - $140,000"},
    "short_description": {"S": "Build and maintain our CI/CD pipelines and cloud infrastructure using Terraform and AWS."},
    "description": {"S": "We are looking for a DevOps Engineer to build and maintain our cloud infrastructure and deployment pipelines. You will be responsible for automating infrastructure provisioning, monitoring, and ensuring high availability of our systems."},
    "responsibilities": {"L": [
      {"S": "Design and implement CI/CD pipelines"}, 
      {"S": "Manage AWS cloud infrastructure using Terraform"}, 
      {"S": "Monitor system performance and troubleshoot issues"}, 
      {"S": "Implement security best practices"}, 
      {"S": "Collaborate with development teams to streamline deployments"}
    ]},
    "requirements": {"L": [
      {"S": "3+ years of DevOps experience"},
      {"S": "Strong knowledge of AWS services"}, 
      {"S": "Experience with infrastructure as code tools like Terraform"}, 
      {"S": "Familiarity with containerization technologies"}, 
      {"S": "Strong scripting skills (Bash, Python)"}
    ]},
    "benefits": {"L": [
      {"S": "Competitive salary package"},
      {"S": "Remote-first work environment"},
      {"S": "Professional certification budget"},
      {"S": "Health insurance"}
    ]},
    "posted_date": {"S": "2025-04-15T00:00:00Z"},
    "status": {"S": "OPEN"}
  }'

echo "Sample job data created successfully!"
