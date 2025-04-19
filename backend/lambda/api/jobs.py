import json
import boto3
import os
import logging
from decimal import Decimal
from boto3.dynamodb.conditions import Key

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
job_table = dynamodb.Table(os.environ['JOB_TABLE_NAME'])

# Helper class for DynamoDB Decimal serialization
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def list_jobs(event, context):
    """
    List all jobs from DynamoDB or filter by category
    """
    try:
        # Check for query parameters
        query_params = event.get('queryStringParameters', {})
        
        if query_params and 'category' in query_params:
            # Filter by category if provided
            category = query_params.get('category')
            response = job_table.query(
                IndexName='CategoryIndex',
                KeyConditionExpression=Key('category').eq(category)
            )
        else:
            # Get all jobs
            response = job_table.scan()
            
        jobs = response.get('Items', [])
        
        # Sort by date (newest first) if we have jobs
        if jobs:
            jobs.sort(key=lambda x: x.get('posted_date', ''), reverse=True)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({'jobs': jobs}, cls=DecimalEncoder)
        }
    except Exception as e:
        logger.error(f"Error listing jobs: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def get_job(event, context):
    """
    Get a specific job by ID
    """
    try:
        # Extract job ID from path parameters
        job_id = event['pathParameters']['jobId']
        
        # Get the job from DynamoDB
        response = job_table.get_item(
            Key={
                'id': job_id
            }
        )
        
        # Check if the job exists
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Job not found'})
            }
        
        # Return the job
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({'job': response['Item']}, cls=DecimalEncoder)
        }
    except Exception as e:
        logger.error(f"Error getting job: {str(e)}")
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
    
    # Route to the appropriate handler
    if http_method == 'GET':
        if path == '/jobs':
            return list_jobs(event, context)
        elif path.startswith('/jobs/') and 'jobId' in event.get('pathParameters', {}):
            return get_job(event, context)
    
    # If we don't have a matching route, return 404
    return {
        'statusCode': 404,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'error': 'Not Found'})
    }
