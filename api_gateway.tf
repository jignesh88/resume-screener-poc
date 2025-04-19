# API Gateway and Lambda Functions for Resume Screener Frontend

#------------------------------------------------------------
# API Gateway
#------------------------------------------------------------
resource "aws_api_gateway_rest_api" "resume_screener_api" {
  name        = "ResumeScreenerAPI"
  description = "API for Resume Screener job listings and applications"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Enable CORS at API level
resource "aws_api_gateway_gateway_response" "cors_response" {
  rest_api_id   = aws_api_gateway_rest_api.resume_screener_api.id
  response_type = "DEFAULT_4XX"
  
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
  }
}

#------------------------------------------------------------
# Jobs Resource
#------------------------------------------------------------
# Jobs Resource
resource "aws_api_gateway_resource" "jobs_resource" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  parent_id   = aws_api_gateway_rest_api.resume_screener_api.root_resource_id
  path_part   = "jobs"
}

# GET /jobs Method
resource "aws_api_gateway_method" "get_jobs" {
  rest_api_id   = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id   = aws_api_gateway_resource.jobs_resource.id
  http_method   = "GET"
  authorization_type = "NONE"
}

# CORS for /jobs
resource "aws_api_gateway_method" "jobs_options" {
  rest_api_id   = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id   = aws_api_gateway_resource.jobs_resource.id
  http_method   = "OPTIONS"
  authorization_type = "NONE"
}

resource "aws_api_gateway_integration" "jobs_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.jobs_resource.id
  http_method = aws_api_gateway_method.jobs_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "jobs_options_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.jobs_resource.id
  http_method = aws_api_gateway_method.jobs_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "jobs_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.jobs_resource.id
  http_method = aws_api_gateway_method.jobs_options.http_method
  status_code = aws_api_gateway_method_response.jobs_options_response.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Integration for GET /jobs
resource "aws_api_gateway_integration" "get_jobs_integration" {
  rest_api_id             = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id             = aws_api_gateway_resource.jobs_resource.id
  http_method             = aws_api_gateway_method.get_jobs.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.jobs_api_lambda.invoke_arn
}

# Response for GET /jobs
resource "aws_api_gateway_method_response" "get_jobs_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.jobs_resource.id
  http_method = aws_api_gateway_method.get_jobs.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

#------------------------------------------------------------
# Job Resource (single job)
#------------------------------------------------------------
# Job Resource {jobId}
resource "aws_api_gateway_resource" "job_resource" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  parent_id   = aws_api_gateway_resource.jobs_resource.id
  path_part   = "{jobId}"
}

# GET /jobs/{jobId} Method
resource "aws_api_gateway_method" "get_job" {
  rest_api_id   = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id   = aws_api_gateway_resource.job_resource.id
  http_method   = "GET"
  authorization_type = "NONE"
  
  request_parameters = {
    "method.request.path.jobId" = true
  }
}

# CORS for /jobs/{jobId}
resource "aws_api_gateway_method" "job_options" {
  rest_api_id   = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id   = aws_api_gateway_resource.job_resource.id
  http_method   = "OPTIONS"
  authorization_type = "NONE"
}

resource "aws_api_gateway_integration" "job_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.job_resource.id
  http_method = aws_api_gateway_method.job_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "job_options_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.job_resource.id
  http_method = aws_api_gateway_method.job_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "job_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.job_resource.id
  http_method = aws_api_gateway_method.job_options.http_method
  status_code = aws_api_gateway_method_response.job_options_response.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Integration for GET /jobs/{jobId}
resource "aws_api_gateway_integration" "get_job_integration" {
  rest_api_id             = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id             = aws_api_gateway_resource.job_resource.id
  http_method             = aws_api_gateway_method.get_job.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.jobs_api_lambda.invoke_arn
}

# Response for GET /jobs/{jobId}
resource "aws_api_gateway_method_response" "get_job_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.job_resource.id
  http_method = aws_api_gateway_method.get_job.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

#------------------------------------------------------------
# Applications Resource
#------------------------------------------------------------
# Applications Resource
resource "aws_api_gateway_resource" "applications_resource" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  parent_id   = aws_api_gateway_rest_api.resume_screener_api.root_resource_id
  path_part   = "applications"
}

# POST /applications Method
resource "aws_api_gateway_method" "post_application" {
  rest_api_id   = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id   = aws_api_gateway_resource.applications_resource.id
  http_method   = "POST"
  authorization_type = "NONE"
}

# CORS for /applications
resource "aws_api_gateway_method" "applications_options" {
  rest_api_id   = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id   = aws_api_gateway_resource.applications_resource.id
  http_method   = "OPTIONS"
  authorization_type = "NONE"
}

resource "aws_api_gateway_integration" "applications_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.applications_resource.id
  http_method = aws_api_gateway_method.applications_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "applications_options_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.applications_resource.id
  http_method = aws_api_gateway_method.applications_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "applications_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.applications_resource.id
  http_method = aws_api_gateway_method.applications_options.http_method
  status_code = aws_api_gateway_method_response.applications_options_response.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Integration for POST /applications
resource "aws_api_gateway_integration" "post_application_integration" {
  rest_api_id             = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id             = aws_api_gateway_resource.applications_resource.id
  http_method             = aws_api_gateway_method.post_application.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.applications_api_lambda.invoke_arn
}

# Response for POST /applications
resource "aws_api_gateway_method_response" "post_application_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.applications_resource.id
  http_method = aws_api_gateway_method.post_application.http_method
  status_code = "201"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

#------------------------------------------------------------
# Application Status Resource
#------------------------------------------------------------
# Application Resource {applicationId}
resource "aws_api_gateway_resource" "application_resource" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  parent_id   = aws_api_gateway_resource.applications_resource.id
  path_part   = "{applicationId}"
}

# GET /applications/{applicationId} Method
resource "aws_api_gateway_method" "get_application" {
  rest_api_id   = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id   = aws_api_gateway_resource.application_resource.id
  http_method   = "GET"
  authorization_type = "NONE"
  
  request_parameters = {
    "method.request.path.applicationId" = true
  }
}

# CORS for /applications/{applicationId}
resource "aws_api_gateway_method" "application_options" {
  rest_api_id   = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id   = aws_api_gateway_resource.application_resource.id
  http_method   = "OPTIONS"
  authorization_type = "NONE"
}

resource "aws_api_gateway_integration" "application_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.application_resource.id
  http_method = aws_api_gateway_method.application_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "application_options_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.application_resource.id
  http_method = aws_api_gateway_method.application_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "application_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.application_resource.id
  http_method = aws_api_gateway_method.application_options.http_method
  status_code = aws_api_gateway_method_response.application_options_response.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Integration for GET /applications/{applicationId}
resource "aws_api_gateway_integration" "get_application_integration" {
  rest_api_id             = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id             = aws_api_gateway_resource.application_resource.id
  http_method             = aws_api_gateway_method.get_application.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.applications_api_lambda.invoke_arn
}

# Response for GET /applications/{applicationId}
resource "aws_api_gateway_method_response" "get_application_response" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  resource_id = aws_api_gateway_resource.application_resource.id
  http_method = aws_api_gateway_method.get_application.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

#------------------------------------------------------------
# API Gateway Deployment
#------------------------------------------------------------
resource "aws_api_gateway_deployment" "resume_screener_deployment" {
  rest_api_id = aws_api_gateway_rest_api.resume_screener_api.id
  stage_name  = "prod"
  
  depends_on = [
    aws_api_gateway_integration.get_jobs_integration,
    aws_api_gateway_integration.get_job_integration,
    aws_api_gateway_integration.post_application_integration,
    aws_api_gateway_integration.get_application_integration,
    aws_api_gateway_integration.jobs_options_integration,
    aws_api_gateway_integration.job_options_integration,
    aws_api_gateway_integration.applications_options_integration,
    aws_api_gateway_integration.application_options_integration
  ]
}

#------------------------------------------------------------
# Lambda Functions for API
#------------------------------------------------------------

# Lambda function for Jobs API
resource "aws_lambda_function" "jobs_api_lambda" {
  filename      = data.archive_file.jobs_api_lambda_package.output_path
  function_name = "JobsAPI"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "jobs.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      JOB_TABLE_NAME = aws_dynamodb_table.job_table.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_custom_policy_attachment
  ]
}

# Lambda function for Applications API
resource "aws_lambda_function" "applications_api_lambda" {
  filename      = data.archive_file.applications_api_lambda_package.output_path
  function_name = "ApplicationsAPI"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "applications.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      APPLICATION_TABLE_NAME = aws_dynamodb_table.application_table.name,
      RESUME_BUCKET_NAME = aws_s3_bucket.resume_bucket.bucket,
      STEP_FUNCTION_ARN = aws_sfn_state_machine.resume_screening_workflow.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_custom_policy_attachment
  ]
}

# Lambda package for Jobs API
data "archive_file" "jobs_api_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/backend/lambda/api/jobs.py"
  output_path = "${path.module}/backend/lambda/api/jobs.zip"
}

# Lambda package for Applications API
data "archive_file" "applications_api_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/backend/lambda/api/applications.py"
  output_path = "${path.module}/backend/lambda/api/applications.zip"
}

#------------------------------------------------------------
# Lambda Permissions for API Gateway
#------------------------------------------------------------

# Permission for API Gateway to invoke Jobs Lambda
resource "aws_lambda_permission" "api_gateway_jobs_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jobs_api_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.resume_screener_api.execution_arn}/*/*/*"
}

# Permission for API Gateway to invoke Applications Lambda
resource "aws_lambda_permission" "api_gateway_applications_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.applications_api_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.resume_screener_api.execution_arn}/*/*/*"
}

#------------------------------------------------------------
# DynamoDB Tables for Jobs and Applications
#------------------------------------------------------------

# DynamoDB Table for Jobs
resource "aws_dynamodb_table" "job_table" {
  name           = "Jobs"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  attribute {
    name = "category"
    type = "S"
  }
  
  global_secondary_index {
    name               = "CategoryIndex"
    hash_key           = "category"
    projection_type    = "ALL"
  }
  
  tags = {
    Name = "JobsTable"
  }
}

# DynamoDB Table for Applications
resource "aws_dynamodb_table" "application_table" {
  name           = "Applications"
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
  
  global_secondary_index {
    name               = "JobIdIndex"
    hash_key           = "jobId"
    projection_type    = "ALL"
  }
  
  tags = {
    Name = "ApplicationsTable"
  }
}

#------------------------------------------------------------
# Outputs for API Gateway
#------------------------------------------------------------

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "${aws_api_gateway_deployment.resume_screener_deployment.invoke_url}"
}

output "jobs_api_url" {
  description = "URL of the Jobs API"
  value       = "${aws_api_gateway_deployment.resume_screener_deployment.invoke_url}/jobs"
}

output "applications_api_url" {
  description = "URL of the Applications API"
  value       = "${aws_api_gateway_deployment.resume_screener_deployment.invoke_url}/applications"
}