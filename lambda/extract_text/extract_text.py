import json
import boto3
import os
import uuid
import logging
from urllib.parse import unquote_plus

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
textract_client = boto3.client('textract')
dynamodb = boto3.resource('dynamodb')

# Get environment variables
RESUME_BUCKET = os.environ['RESUME_BUCKET']
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
candidate_table = dynamodb.Table(DYNAMODB_TABLE)

def extract_text_from_document(bucket, document_key):
    """
    Use Amazon Textract to extract text from a document stored in S3
    """
    logger.info(f"Extracting text from {document_key}")
    
    # Determine document type from extension
    file_extension = document_key.lower().split('.')[-1]
    
    try:
        if file_extension in ['pdf', 'doc', 'docx']:
            # Use Textract to extract text from document
            response = textract_client.start_document_text_detection(
                DocumentLocation={
                    'S3Object': {
                        'Bucket': bucket,
                        'Name': document_key
                    }
                }
            )
            job_id = response['JobId']
            
            # Wait for the job to complete
            while True:
                response = textract_client.get_document_text_detection(JobId=job_id)
                status = response['JobStatus']
                if status in ['SUCCEEDED', 'FAILED']:
                    break
                
            # If job succeeded, extract the text
            if status == 'SUCCEEDED':
                text = ""
                for item in response['Blocks']:
                    if item['BlockType'] == 'LINE':
                        text += item['Text'] + "\n"
                
                # Get all pages if there are more
                next_token = response.get('NextToken', None)
                while next_token:
                    response = textract_client.get_document_text_detection(
                        JobId=job_id,
                        NextToken=next_token
                    )
                    for item in response['Blocks']:
                        if item['BlockType'] == 'LINE':
                            text += item['Text'] + "\n"
                    next_token = response.get('NextToken', None)
                
                return text
        else:
            # For other file types, handle accordingly or raise an error
            raise ValueError(f"Unsupported file type: {file_extension}")
    
    except Exception as e:
        logger.error(f"Error extracting text from document: {str(e)}")
        raise

def store_resume_data(candidate_id, job_id, text_content, file_path):
    """
    Store extracted resume data in DynamoDB
    """
    try:
        item = {
            'id': candidate_id,
            'jobId': job_id,
            'resumeText': text_content,
            'resumePath': file_path,
            'status': 'EXTRACTED',
            'timestamp': int(boto3.client('dynamodb').get_item(
                TableName='candidate-tracking',
                Key={'id': {'S': candidate_id}}
            ).get('Item', {}).get('timestamp', {'N': '0'}).get('N', '0')) or int(boto3.client('dynamodb').get_item(
                TableName='candidate-tracking',
                Key={'id': {'S': candidate_id}}
            ).get('Item', {}).get('timestamp', {'N': '0'}).get('N', '0'))
        }
        
        # Store in DynamoDB
        candidate_table.put_item(Item=item)
        logger.info(f"Stored resume data for candidate {candidate_id}")
        return True
    
    except Exception as e:
        logger.error(f"Error storing resume data: {str(e)}")
        return False

def lambda_handler(event, context):
    """
    Lambda handler for extracting text from resumes
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # If event is from S3
        if 'Records' in event and event['Records'][0]['eventSource'] == 'aws:s3':
            bucket = event['Records'][0]['s3']['bucket']['name']
            key = unquote_plus(event['Records'][0]['s3']['object']['key'])
            
            # Extract candidate ID and job ID from file path
            # Assuming path pattern: resumes/{job_id}/{candidate_id}.pdf
            path_parts = key.split('/')
            if len(path_parts) >= 3 and path_parts[0] == 'resumes':
                job_id = path_parts[1]
                candidate_id = path_parts[2].split('.')[0]
            else:
                # Generate IDs if path pattern doesn't match
                job_id = 'default-job'
                candidate_id = str(uuid.uuid4())
            
            # Extract text from the document
            text_content = extract_text_from_document(bucket, key)
            
            # Store the extracted text in DynamoDB
            store_resume_data(candidate_id, job_id, text_content, key)
            
            return {
                'statusCode': 200,
                'candidateId': candidate_id,
                'jobId': job_id,
                'textExtracted': True
            }
        
        # If event is from Step Functions
        elif 'candidateId' in event and 'jobId' in event:
            candidate_id = event['candidateId']
            job_id = event['jobId']
            file_path = f"resumes/{job_id}/{candidate_id}.pdf"
            
            # Extract text from the document
            text_content = extract_text_from_document(RESUME_BUCKET, file_path)
            
            # Store the extracted text in DynamoDB
            store_resume_data(candidate_id, job_id, text_content, file_path)
            
            return {
                'statusCode': 200,
                'candidateId': candidate_id,
                'jobId': job_id,
                'textExtracted': True
            }
        
        else:
            raise ValueError("Invalid event structure")
    
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'error': str(e),
            'textExtracted': False
        }