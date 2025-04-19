variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "ap-southeast-2"
}

variable "resume_bucket_name" {
  description = "Name of the S3 bucket for storing resumes and call recordings"
  type        = string
  default     = "candidate-resumes-recordings"
}

variable "opensearch_domain_name" {
  description = "Name of the OpenSearch domain for vector search"
  type        = string
  default     = "resume-search-domain"
}

variable "opensearch_master_user" {
  description = "Master username for OpenSearch"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "opensearch_master_password" {
  description = "Master password for OpenSearch"
  type        = string
  sensitive   = true
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for candidate tracking"
  type        = string
  default     = "candidate-tracking"
}

variable "connect_instance_id" {
  description = "Amazon Connect instance ID (manually created)"
  type        = string
}

variable "connect_contact_flow_id" {
  description = "Amazon Connect contact flow ID (manually created)"
  type        = string
}

variable "bedrock_model_id" {
  description = "Amazon Bedrock model ID to use for AI processing"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "gmail_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Gmail API credentials"
  type        = string
}

variable "hiring_manager_email" {
  description = "Email address of the hiring manager"
  type        = string
}

variable "technical_staff_email" {
  description = "Email address of the technical staff"
  type        = string
}

variable "company_name" {
  description = "Name of the company"
  type        = string
  default     = "Example Corp"
}

variable "company_phone" {
  description = "Phone number of the company"
  type        = string
}