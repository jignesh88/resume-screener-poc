provider "aws" {
  region = var.aws_region
}

#------------------------------------------------------------
# S3 Bucket for Resume Storage and Call Recordings
#------------------------------------------------------------
resource "aws_s3_bucket" "resume_bucket" {
  bucket = var.resume_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "resume_bucket_versioning" {
  bucket = aws_s3_bucket.resume_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "resume_bucket_block" {
  bucket = aws_s3_bucket.resume_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#------------------------------------------------------------
# DynamoDB Table for Candidate Rankings and Tracking
#------------------------------------------------------------
resource "aws_dynamodb_table" "candidate_table" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  attribute {
    name = "jobId"
    type = "S"
  }
  
  attribute {
    name = "ranking"
    type = "N"
  }
  
  global_secondary_index {
    name               = "JobRankingIndex"
    hash_key           = "jobId"
    range_key          = "ranking"
    projection_type    = "ALL"
  }
  
  tags = {
    Name = "CandidateTrackingTable"
  }
}

#------------------------------------------------------------
# Amazon OpenSearch Service for Vector Search
#------------------------------------------------------------
resource "aws_opensearch_domain" "resume_search" {
  domain_name    = var.opensearch_domain_name
  engine_version = "OpenSearch_2.5"

  cluster_config {
    instance_type = "t3.small.search"
    instance_count = 1
    zone_awareness_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name = var.opensearch_master_user
      master_user_password = var.opensearch_master_password
    }
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.lambda_execution_role.arn}"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain_name}/*"
    }
  ]
}
CONFIG

  tags = {
    Name = "ResumeSearchDomain"
  }

  depends_on = [aws_iam_service_linked_role.opensearch_service_role]
}

# OpenSearch service-linked role
resource "aws_iam_service_linked_role" "opensearch_service_role" {
  aws_service_name = "opensearchservice.amazonaws.com"
  description      = "Service-linked role for OpenSearch"
}

#------------------------------------------------------------
# AWS Identity Data
#------------------------------------------------------------
data "aws_caller_identity" "current" {}

#------------------------------------------------------------
# IAM Roles and Policies
#------------------------------------------------------------
# Lambda execution role
resource "aws_iam_role" "lambda_execution_role" {
  name = "ResumeScreeningLambdaExecutionRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda custom policy for all required permissions
resource "aws_iam_policy" "lambda_custom_policy" {
  name        = "ResumeScreeningLambdaPolicy"
  description = "Policy for Lambda to access S3, Textract, Bedrock, OpenSearch, DynamoDB, etc."
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.resume_bucket.arn}",
          "${aws_s3_bucket.resume_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "textract:AnalyzeDocument",
          "textract:DetectDocumentText",
          "textract:GetDocumentAnalysis",
          "textract:GetDocumentTextDetection",
          "textract:StartDocumentAnalysis",
          "textract:StartDocumentTextDetection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeAgent",
          "bedrock:InvokeAgentWithResponseStream",
          "bedrock:GetAgent",
          "bedrock:ListAgents",
          "bedrock:CreateAgent",
          "bedrock:Retrieve"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.candidate_table.arn,
          "${aws_dynamodb_table.candidate_table.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "connect:StartOutboundVoiceContact",
          "connect:StopContact"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = "*"  # Use wildcard to avoid circular dependency
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_custom_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_custom_policy.arn
}

# Step Functions execution role
resource "aws_iam_role" "step_functions_execution_role" {
  name = "ResumeScreeningStepFunctionsExecutionRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "step_functions_policy" {
  name        = "ResumeScreeningStepFunctionsPolicy"
  description = "Policy for Step Functions to invoke Lambda functions"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.extract_text_lambda.arn,
          aws_lambda_function.screen_resume_lambda.arn,
          aws_lambda_function.rank_candidates_lambda.arn,
          aws_lambda_function.phone_interview_lambda.arn,
          aws_lambda_function.schedule_interview_lambda.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions_policy_attachment" {
  role       = aws_iam_role.step_functions_execution_role.name
  policy_arn = aws_iam_policy.step_functions_policy.arn
}

#------------------------------------------------------------
# Lambda Functions
#------------------------------------------------------------

# Lambda function for text extraction from documents
resource "aws_lambda_function" "extract_text_lambda" {
  filename      = data.archive_file.extract_text_lambda_package.output_path
  function_name = "ExtractTextFromResume"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "extract_text.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

  environment {
    variables = {
      RESUME_BUCKET = aws_s3_bucket.resume_bucket.bucket,
      DYNAMODB_TABLE = aws_dynamodb_table.candidate_table.name,
      OPENSEARCH_DOMAIN = aws_opensearch_domain.resume_search.endpoint
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_custom_policy_attachment
  ]
}

# Lambda function for resume screening
resource "aws_lambda_function" "screen_resume_lambda" {
  filename      = data.archive_file.screen_resume_lambda_package.output_path
  function_name = "ScreenResume"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "screen_resume.lambda_handler"
  runtime       = "python3.11"
  timeout       = 120
  memory_size   = 512

  environment {
    variables = {
      BEDROCK_MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0",
      DYNAMODB_TABLE = aws_dynamodb_table.candidate_table.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_custom_policy_attachment
  ]
}

# Lambda function for candidate ranking
resource "aws_lambda_function" "rank_candidates_lambda" {
  filename      = data.archive_file.rank_candidates_lambda_package.output_path
  function_name = "RankCandidates"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "rank_candidates.lambda_handler"
  runtime       = "python3.11"
  timeout       = 120
  memory_size   = 512

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.candidate_table.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_custom_policy_attachment
  ]
}

# Lambda function for phone interview
resource "aws_lambda_function" "phone_interview_lambda" {
  filename      = data.archive_file.phone_interview_lambda_package.output_path
  function_name = "PhoneInterview"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "phone_interview.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

  environment {
    variables = {
      CONNECT_INSTANCE_ID = var.connect_instance_id,
      CONNECT_CONTACT_FLOW_ID = var.connect_contact_flow_id,
      DYNAMODB_TABLE = aws_dynamodb_table.candidate_table.name,
      BEDROCK_MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_custom_policy_attachment
  ]
}

# Lambda function for interview scheduling
resource "aws_lambda_function" "schedule_interview_lambda" {
  filename      = data.archive_file.schedule_interview_lambda_package.output_path
  function_name = "ScheduleInterview"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "schedule_interview.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

  environment {
    variables = {
      GMAIL_CREDENTIALS_SECRET = var.gmail_credentials_secret_arn,
      DYNAMODB_TABLE = aws_dynamodb_table.candidate_table.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_custom_policy_attachment
  ]
}

#------------------------------------------------------------
# Lambda Function Packages (ZIP files)
#------------------------------------------------------------
data "archive_file" "extract_text_lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/extract_text"
  output_path = "${path.module}/lambda/extract_text.zip"
}

data "archive_file" "screen_resume_lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/screen_resume"
  output_path = "${path.module}/lambda/screen_resume.zip"
}

data "archive_file" "rank_candidates_lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/rank_candidates"
  output_path = "${path.module}/lambda/rank_candidates.zip"
}

data "archive_file" "phone_interview_lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/phone_interview"
  output_path = "${path.module}/lambda/phone_interview.zip"
}

data "archive_file" "schedule_interview_lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/schedule_interview"
  output_path = "${path.module}/lambda/schedule_interview.zip"
}

#------------------------------------------------------------
# CloudWatch Log Groups
#------------------------------------------------------------
resource "aws_cloudwatch_log_group" "extract_text_logs" {
  name              = "/aws/lambda/${aws_lambda_function.extract_text_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "screen_resume_logs" {
  name              = "/aws/lambda/${aws_lambda_function.screen_resume_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "rank_candidates_logs" {
  name              = "/aws/lambda/${aws_lambda_function.rank_candidates_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "phone_interview_logs" {
  name              = "/aws/lambda/${aws_lambda_function.phone_interview_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "schedule_interview_logs" {
  name              = "/aws/lambda/${aws_lambda_function.schedule_interview_lambda.function_name}"
  retention_in_days = 30
}

#------------------------------------------------------------
# CloudWatch Metrics Alarms
#------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "lambda_errors_alarm" {
  alarm_name          = "ResumeScreeningLambdaErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 2
  alarm_description   = "This alarm monitors Lambda function errors"
  
  dimensions = {
    FunctionName = aws_lambda_function.screen_resume_lambda.function_name
  }
}

#------------------------------------------------------------
# Bedrock Knowledge Base (Manual setup required - See README)
#------------------------------------------------------------
# Note: Bedrock Knowledge Base must be set up manually
# See README.md for instructions