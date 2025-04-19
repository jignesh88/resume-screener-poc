# Step Functions definition for the resume screening and interview workflow

# Step Functions state machine
resource "aws_sfn_state_machine" "resume_screening_workflow" {
  name     = "ResumeScreeningWorkflow"
  role_arn = aws_iam_role.step_functions_execution_role.arn
  
  definition = <<EOF
{
  "Comment": "Resume screening and interview workflow with enhanced error handling",
  "StartAt": "ExtractText",
  "States": {
    "ExtractText": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.extract_text_lambda.arn}",
      "ResultPath": "$.extractionResult",
      "Retry": [
        {
          "ErrorEquals": ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
          "IntervalSeconds": 2,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "ExtractTextFailed"
        }
      ],
      "Next": "ScreenResume"
    },
    "ExtractTextFailed": {
      "Type": "Pass",
      "ResultPath": "$.extractionError",
      "Parameters": {
        "error.$": "$.error",
        "message": "Text extraction from resume failed",
        "timestamp.$": "$$.State.EnteredTime"
      },
      "End": true
    },
    "ScreenResume": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.screen_resume_lambda.arn}",
      "InputPath": "$",
      "ResultPath": "$.screeningResult",
      "Retry": [
        {
          "ErrorEquals": ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "ServiceUnavailable"],
          "IntervalSeconds": 2,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "ScreeningFailed"
        }
      ],
      "Next": "RankCandidates"
    },
    "ScreeningFailed": {
      "Type": "Pass",
      "ResultPath": "$.screeningError",
      "Parameters": {
        "error.$": "$.error",
        "message": "Resume screening with Bedrock failed",
        "timestamp.$": "$$.State.EnteredTime"
      },
      "End": true
    },
    "RankCandidates": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.rank_candidates_lambda.arn}",
      "InputPath": "$",
      "ResultPath": "$.rankingResult",
      "Retry": [
        {
          "ErrorEquals": ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
          "IntervalSeconds": 2,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "RankingFailed"
        }
      ],
      "Next": "IsTopCandidate"
    },
    "RankingFailed": {
      "Type": "Pass",
      "ResultPath": "$.rankingError",
      "Parameters": {
        "error.$": "$.error",
        "message": "Candidate ranking failed",
        "timestamp.$": "$$.State.EnteredTime"
      },
      "End": true
    },
    "IsTopCandidate": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.rankingResult.isTopCandidate",
          "BooleanEquals": true,
          "Next": "PhoneInterview"
        }
      ],
      "Default": "NotTopCandidate"
    },
    "NotTopCandidate": {
      "Type": "Pass",
      "ResultPath": "$.status",
      "Parameters": {
        "message": "Candidate did not rank in the top 5%, no phone interview will be conducted",
        "timestamp.$": "$$.State.EnteredTime",
        "jobId.$": "$.jobId",
        "candidateId.$": "$.candidateId",
        "ranking.$": "$.rankingResult.ranking",
        "screeningScore.$": "$.screeningResult.evaluation.score"
      },
      "End": true
    },
    "PhoneInterview": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.phone_interview_lambda.arn}",
      "InputPath": "$",
      "ResultPath": "$.interviewResult",
      "Retry": [
        {
          "ErrorEquals": ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
          "IntervalSeconds": 2,
          "MaxAttempts": 2,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "PhoneInterviewFailed"
        }
      ],
      "Next": "CheckInterviewSuccess"
    },
    "PhoneInterviewFailed": {
      "Type": "Pass",
      "ResultPath": "$.interviewError",
      "Parameters": {
        "error.$": "$.error",
        "message": "Phone interview process failed",
        "timestamp.$": "$$.State.EnteredTime"
      },
      "End": true
    },
    "CheckInterviewSuccess": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.interviewResult.passedPhoneInterview",
          "BooleanEquals": true,
          "Next": "ScheduleInterview"
        }
      ],
      "Default": "PhoneInterviewFailed"
    },
    "ScheduleInterview": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.schedule_interview_lambda.arn}",
      "InputPath": "$",
      "ResultPath": "$.schedulingResult",
      "Retry": [
        {
          "ErrorEquals": ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"],
          "IntervalSeconds": 2,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "ResultPath": "$.error",
          "Next": "SchedulingFailed"
        }
      ],
      "Next": "ProcessCompleted"
    },
    "SchedulingFailed": {
      "Type": "Pass",
      "ResultPath": "$.schedulingError",
      "Parameters": {
        "error.$": "$.error",
        "message": "Interview scheduling failed",
        "timestamp.$": "$$.State.EnteredTime"
      },
      "End": true
    },
    "ProcessCompleted": {
      "Type": "Pass",
      "ResultPath": "$.processStatus",
      "Parameters": {
        "message": "Candidate screening and interview scheduling completed successfully",
        "candidateId.$": "$.candidateId",
        "jobId.$": "$.jobId",
        "interviewDateTime.$": "$.schedulingResult.interviewDateTime",
        "timestamp.$": "$$.State.EnteredTime"
      },
      "End": true
    }
  }
}
EOF
}

# Create CloudWatch Metrics and alarms for the Step Functions execution
resource "aws_cloudwatch_metric_alarm" "step_functions_execution_failed" {
  alarm_name          = "ResumeScreeningWorkflowFailed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "This alarm monitors failed Step Functions executions"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    StateMachineArn = aws_sfn_state_machine.resume_screening_workflow.arn
  }
}

# EventBridge rule to capture Step Functions state transitions for monitoring
resource "aws_cloudwatch_event_rule" "step_functions_state_change" {
  name        = "capture-step-functions-state-change"
  description = "Capture Step Functions state transitions"
  
  event_pattern = jsonencode({
    source      = ["aws.states"],
    detail_type = ["Step Functions Execution Status Change"],
    detail      = {
      stateMachineArn = [aws_sfn_state_machine.resume_screening_workflow.arn]
    }
  })
}

# CloudWatch Logs group for Step Functions state transitions
resource "aws_cloudwatch_log_group" "step_functions_logs" {
  name              = "/aws/states/${aws_sfn_state_machine.resume_screening_workflow.name}/transitions"
  retention_in_days = 30
}

# EventBridge target for sending state transitions to CloudWatch Logs
resource "aws_cloudwatch_event_target" "step_functions_logs" {
  rule      = aws_cloudwatch_event_rule.step_functions_state_change.name
  arn       = aws_cloudwatch_log_group.step_functions_logs.arn
  
  # Format the log entry
  input_transformer {
    input_paths = {
      execution = "$.detail.executionArn",
      state = "$.detail.status",
      stateMachine = "$.detail.stateMachineArn",
      input = "$.detail.input"
    }
    input_template = "\"State Machine '${aws_sfn_state_machine.resume_screening_workflow.name}' execution '<execution>' changed to state '<state>' with input: <input>\""
  }
}
