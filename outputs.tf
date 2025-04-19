output "resume_bucket_name" {
  description = "Name of the S3 bucket for resume storage"
  value       = aws_s3_bucket.resume_bucket.bucket
}

output "resume_bucket_arn" {
  description = "ARN of the S3 bucket for resume storage"
  value       = aws_s3_bucket.resume_bucket.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for candidate tracking"
  value       = aws_dynamodb_table.candidate_table.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for candidate tracking"
  value       = aws_dynamodb_table.candidate_table.arn
}

output "opensearch_domain_endpoint" {
  description = "Endpoint of the OpenSearch domain"
  value       = "https://${aws_opensearch_domain.resume_search.endpoint}"
}

output "opensearch_domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.resume_search.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "extract_text_lambda_arn" {
  description = "ARN of the Extract Text Lambda function"
  value       = aws_lambda_function.extract_text_lambda.arn
}

output "screen_resume_lambda_arn" {
  description = "ARN of the Screen Resume Lambda function"
  value       = aws_lambda_function.screen_resume_lambda.arn
}

output "rank_candidates_lambda_arn" {
  description = "ARN of the Rank Candidates Lambda function"
  value       = aws_lambda_function.rank_candidates_lambda.arn
}

output "phone_interview_lambda_arn" {
  description = "ARN of the Phone Interview Lambda function"
  value       = aws_lambda_function.phone_interview_lambda.arn
}

output "schedule_interview_lambda_arn" {
  description = "ARN of the Schedule Interview Lambda function"
  value       = aws_lambda_function.schedule_interview_lambda.arn
}

output "step_functions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.resume_screening_workflow.arn
}

# Note: API Gateway outputs are already defined in api_gateway.tf