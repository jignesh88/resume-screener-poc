import json
import boto3
import os
import uuid
import base64
import logging
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
sfn_client = boto3.client('stepfunctions')

# Get environment variables
APPLICATION_TABLE_NAME = os.environ['APPLICATION_TABLE_NAME']
RESUME_BUCKET_NAME = os.environ['RESUME_BUCKET_NAME']
STEP_FUNCTION_ARN = os.environ['STEP_FUNCTION_ARN']

application_table = dynamodb.Table(APPLICATION_TABLE_NAME)

def submit_application(event, context):
    """
    Handle job application submission with resume upload
    """
    try:
        # Parse request body
        if 'body' not in event or not event['body']:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Missing request body'})
            }
        
        # Parse JSON body
        body = json.loads(event['body'])
        
        # Validate required fields
        required_fields = ['jobId', 'fullName', 'email', 'phone', 'resume']
        for field in required_fields:
            if field not in body:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({'error': f'Missing required field: {field}'})
                }
        
        # Generate a unique ID for the application
        application_id = str(uuid.uuid4())
        job_id = body['jobId']
        
        # Extract resume data - we expect base64 encoded file
        resume_data = body['resume']
        if ';base64,' in resume_data:
            # Extract the actual base64 content after the data URI scheme
            _, resume_base64 = resume_data.split(';base64,')
        else:
            resume_base64 = resume_data
            
        try:
            resume_binary = base64.b64decode(resume_base64)
        except Exception as e:
            logger.error(f"Error decoding resume: {str(e)}")
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Invalid resume data format'})
            }
        
        # Upload the resume to S3
        resume_key = f"resumes/{job_id}/{application_id}.pdf"
        s3_client.put_object(
            Bucket=RESUME_BUCKET_NAME,
            Key=resume_key,
            Body=resume_binary,
            ContentType='application/pdf'
        )
        
        # Save application details to DynamoDB
        timestamp = datetime.now().isoformat()
        application_item = {
            'id': application_id,
            'jobId': job_id,
            'fullName': body['fullName'],
            'email': body['email'],
            'phone': body['phone'],
            'resumeKey': resume_key,
            'status': 'SUBMITTED',
            'submissionDate': timestamp,
            'updatedDate': timestamp
        }
        
        # Add optional fields if present
        optional_fields = ['coverLetter', 'linkedIn', 'portfolio', 'additionalInfo']
        for field in optional_fields:
            if field in body and body[field]:
                application_item[field] = body[field]
        
        # Save to DynamoDB
        application_table.put_item(Item=application_item)
        
        # Start the Step Function workflow for resume screening
        sfn_client.start_execution(
            stateMachineArn=STEP_FUNCTION_ARN,
            input=json.dumps({
                'candidateId': application_id,
                'jobId': job_id
            })
        )
        
        # Return success response
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'applicationId': application_id,
                'status': 'SUBMITTED',
                'message': 'Application submitted successfully'
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing application: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def get_application_status(event, context):
    """
    Check the status of a job application
    """
    try:
        # Extract application ID from path parameters
        application_id = event['pathParameters']['applicationId']
        
        # Get the application from DynamoDB
        response = application_table.get_item(
            Key={
                'id': application_id
            }
        )
        
        # Check if the application exists
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Application not found'})
            }
        
        # Return the application status
        application = response['Item']
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'applicationId': application['id'],
                'jobId': application['jobId'],
                'status': application['status'],
                'submissionDate': application['submissionDate'],
                'updatedDate': application['updatedDate']
            })
        }
    except Exception as e:
        logger.error(f"Error getting application status: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def lambda_handler(event, context):
    """
    Route the request to the appropriate handler based on HTTP method and path
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Get the HTTP method
    http_method = event['httpMethod']
    
    # Get the path
    path = event['path']
    
    # Handle OPTIONS requests for CORS
    if http_method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': ''
        }
    
    # Route to the appropriate handler
    if http_method == 'POST' and path == '/applications':
        return submit_application(event, context)
    elif http_method == 'GET' and path.startswith('/applications/') and 'applicationId' in event.get('pathParameters', {}):
        return get_application_status(event, context)
    
    # If we don't have a matching route, return 404
    return {
        'statusCode': 404,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'error': 'Not Found'})
    }
