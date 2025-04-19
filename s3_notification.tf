# S3 Event Notification Configuration
# This configures the S3 bucket to trigger the Step Functions workflow when new resumes are uploaded

# IAM role for S3 to invoke Step Functions
resource "aws_iam_role" "s3_step_functions_role" {
  name = "S3StepFunctionsInvokeRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for S3 to invoke Step Functions
resource "aws_iam_policy" "s3_step_functions_policy" {
  name        = "S3StepFunctionsInvokePolicy"
  description = "Policy allowing S3 to invoke Step Functions"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = [
          aws_sfn_state_machine.resume_screening_workflow.arn
        ]
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "s3_step_functions_attachment" {
  role       = aws_iam_role.s3_step_functions_role.name
  policy_arn = aws_iam_policy.s3_step_functions_policy.arn
}

# S3 bucket notification configuration
resource "aws_s3_bucket_notification" "resume_upload_notification" {
  bucket = aws_s3_bucket.resume_bucket.id

  # Option 1: Direct Lambda invocation
  lambda_function {
    lambda_function_arn = aws_lambda_function.extract_text_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "resumes/"
    filter_suffix       = ".pdf"
  }

  # Note: For production, you might want to use a Step Functions trigger directly
  # This would require using AWS CloudWatch Events/EventBridge as S3 doesn't directly
  # trigger Step Functions in Terraform yet
  
  depends_on = [
    aws_lambda_permission.allow_s3_invoke
  ]
}

# Lambda permission for S3 invocation
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.extract_text_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.resume_bucket.arn
}

# Note: For a more robust solution, you can use EventBridge to trigger Step Functions directly
# This would require creating an EventBridge rule that watches for S3 object creation events
# and targets the Step Functions state machine