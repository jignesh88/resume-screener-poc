import json
import boto3
import os
import logging
import time
from decimal import Decimal
import uuid

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
connect = boto3.client('connect')
bedrock = boto3.client('bedrock-runtime')
dynamodb = boto3.resource('dynamodb')

# Get environment variables
CONNECT_INSTANCE_ID = os.environ['CONNECT_INSTANCE_ID']
CONNECT_CONTACT_FLOW_ID = os.environ['CONNECT_CONTACT_FLOW_ID']
BEDROCK_MODEL_ID = os.environ['BEDROCK_MODEL_ID']
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
candidate_table = dynamodb.Table(DYNAMODB_TABLE)

# JSON helper class for Decimal types
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def get_candidate_data(candidate_id):
    """
    Retrieve candidate data from DynamoDB
    """
    try:
        response = candidate_table.get_item(
            Key={'id': candidate_id}
        )
        
        if 'Item' not in response:
            logger.error(f"No data found for candidate {candidate_id}")
            return None
        
        return response['Item']
    
    except Exception as e:
        logger.error(f"Error retrieving candidate data: {str(e)}")
        return None

def generate_interview_script(candidate_data, job_id):
    """
    Use Amazon Bedrock to generate a personalized interview script
    """
    try:
        # Get job description
        job_description = get_job_description(job_id)
        
        # Get candidate information
        candidate_name = candidate_data.get('name', 'Candidate')
        screening_results = candidate_data.get('screening', {})
        matching_skills = screening_results.get('matching_skills', [])
        missing_skills = screening_results.get('missing_skills', [])
        
        # Construct the prompt for Bedrock
        prompt = f"""
        You are an AI assistant for a recruiting team. Your task is to create a phone interview script for a candidate.
        
        JOB DESCRIPTION:
        {job_description}
        
        CANDIDATE INFORMATION:
        Name: {candidate_name}
        Matching Skills: {', '.join(matching_skills)}
        Skills to Validate: {', '.join(missing_skills)}
        
        Please generate a complete phone interview script with:
        
        1. An introduction explaining who you are and the purpose of the call
        2. 3-5 questions to validate the candidate's relevant experience
        3. 2-3 questions to assess the candidate's fit for the role
        4. 1-2 questions to probe deeper into any skills gaps
        5. An opportunity for the candidate to ask questions
        6. A conclusion explaining next steps
        
        The script should be conversational, professional, and designed to be read by a voice assistant during a phone call.
        """
        
        # Call Bedrock with the prompt
        response = bedrock.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 2000,
                "temperature": 0.7,
                "messages": [
                    {
                        "role": "user", 
                        "content": prompt
                    }
                ]
            })
        )
        
        # Parse the response
        response_body = json.loads(response['body'].read().decode('utf-8'))
        interview_script = response_body['content'][0]['text']
        
        return interview_script
    
    except Exception as e:
        logger.error(f"Error generating interview script: {str(e)}")
        raise

def get_job_description(job_id):
    """
    Get job description for a given job ID
    This is a placeholder function - in a real implementation,
    you would retrieve this from a database
    """
    # Sample job descriptions (same as in screen_resume.py)
    job_descriptions = {
        "software-engineer": """
        Software Engineer
        
        Responsibilities:
        - Design, develop, and maintain high-quality software solutions
        - Write clean, efficient, and maintainable code
        - Collaborate with cross-functional teams to define and implement new features
        - Troubleshoot and debug applications
        - Participate in code reviews and contribute to team knowledge sharing
        
        Requirements:
        - Bachelor's degree in Computer Science or related field
        - 3+ years of experience in software development
        - Proficiency in Python, Java, or similar programming languages
        - Experience with cloud technologies (AWS, Azure, or GCP)
        - Knowledge of software engineering best practices
        - Strong problem-solving skills and attention to detail
        - Excellent communication and teamwork abilities
        """,
        
        # Additional job descriptions omitted for brevity...
    }
    
    # Return the job description for the given job ID, or a default one if not found
    return job_descriptions.get(job_id, "Generic Technical Position")

def initiate_phone_call(candidate_phone, interview_script):
    """
    Initiate a phone call using Amazon Connect
    """
    try:
        attributes = {
            'interviewScript': interview_script
        }
        
        response = connect.start_outbound_voice_contact(
            DestinationPhoneNumber=candidate_phone,
            ContactFlowId=CONNECT_CONTACT_FLOW_ID,
            InstanceId=CONNECT_INSTANCE_ID,
            Attributes=attributes
        )
        
        return response['ContactId']
    
    except Exception as e:
        logger.error(f"Error initiating phone call: {str(e)}")
        raise

def update_candidate_phone_interview(candidate_id, contact_id, interview_script):
    """
    Update the candidate's record with phone interview details
    """
    try:
        update_expression = """
        SET phoneInterview = :phoneInterview,
            status = :status
        """
        
        expression_values = {
            ':phoneInterview': {
                'contactId': contact_id,
                'script': interview_script,
                'timestamp': int(time.time()),
                'status': 'INITIATED'
            },
            ':status': 'PHONE_INTERVIEW_INITIATED'
        }
        
        candidate_table.update_item(
            Key={'id': candidate_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values
        )
        
        logger.info(f"Updated phone interview details for candidate {candidate_id}")
        return True
    
    except Exception as e:
        logger.error(f"Error updating phone interview details: {str(e)}")
        return False

def process_phone_interview_results(candidate_id, interview_results):
    """
    Process the results of a phone interview
    This would be called by a callback from Amazon Connect after the call
    """
    try:
        # In a real implementation, you would analyze the call recording
        # or transcript using Amazon Transcribe and Bedrock
        # For this example, we'll simulate a successful interview
        
        passed_interview = True
        interview_notes = "Candidate performed well in the phone interview."
        
        update_expression = """
        SET phoneInterview.status = :status,
            phoneInterview.notes = :notes,
            phoneInterview.passed = :passed,
            status = :candidateStatus
        """
        
        expression_values = {
            ':status': 'COMPLETED',
            ':notes': interview_notes,
            ':passed': passed_interview,
            ':candidateStatus': 'PHONE_INTERVIEW_COMPLETED'
        }
        
        candidate_table.update_item(
            Key={'id': candidate_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values
        )
        
        return {
            'candidateId': candidate_id,
            'passedPhoneInterview': passed_interview,
            'notes': interview_notes
        }
    
    except Exception as e:
        logger.error(f"Error processing phone interview results: {str(e)}")
        return {
            'candidateId': candidate_id,
            'passedPhoneInterview': False,
            'error': str(e)
        }

def lambda_handler(event, context):
    """
    Lambda handler for phone interviews
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Check if this is a new phone interview request or a callback
        if event.get('action') == 'process_results':
            # Process the results of a completed phone interview
            candidate_id = event.get('candidateId')
            interview_results = event.get('results', {})
            
            result = process_phone_interview_results(candidate_id, interview_results)
            
            return {
                'statusCode': 200,
                'candidateId': candidate_id,
                'jobId': event.get('jobId'),
                'passedPhoneInterview': result.get('passedPhoneInterview', False),
                'processed': True
            }
        
        else:
            # Initiate a new phone interview
            if 'candidateId' not in event or 'jobId' not in event:
                raise ValueError("Missing required parameters: candidateId and jobId")
            
            candidate_id = event['candidateId']
            job_id = event['jobId']
            
            # Get the candidate data
            candidate_data = get_candidate_data(candidate_id)
            if not candidate_data:
                raise ValueError(f"No data found for candidate {candidate_id}")
            
            # Check if candidate has a phone number
            candidate_phone = candidate_data.get('phone')
            if not candidate_phone:
                raise ValueError(f"No phone number found for candidate {candidate_id}")
            
            # Generate the interview script
            interview_script = generate_interview_script(candidate_data, job_id)
            
            # Initiate the phone call
            contact_id = initiate_phone_call(candidate_phone, interview_script)
            
            # Update the candidate's record
            update_candidate_phone_interview(candidate_id, contact_id, interview_script)
            
            # For this example, we'll simulate the interview results after a delay
            # In a real implementation, this would come from a callback from Amazon Connect
            
            # Simulate interview results
            result = process_phone_interview_results(candidate_id, {
                'contactId': contact_id,
                'callStatus': 'COMPLETED',
                'callDuration': 300,  # 5 minutes
                'callRecordingUrl': f"s3://call-recordings/{contact_id}.wav"
            })
            
            return {
                'statusCode': 200,
                'candidateId': candidate_id,
                'jobId': job_id,
                'contactId': contact_id,
                'initiated': True,
                'passedPhoneInterview': result.get('passedPhoneInterview', False)
            }
    
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'error': str(e),
            'initiated': False,
            'passedPhoneInterview': False
        }