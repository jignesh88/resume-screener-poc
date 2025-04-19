import json
import boto3
import os
import logging
import base64
import time
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
import random

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
secretsmanager = boto3.client('secretsmanager')
ses = boto3.client('ses')
dynamodb = boto3.resource('dynamodb')

# Get environment variables
GMAIL_CREDENTIALS_SECRET = os.environ['GMAIL_CREDENTIALS_SECRET']
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
candidate_table = dynamodb.Table(DYNAMODB_TABLE)

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

def get_gmail_credentials():
    """
    Retrieve Gmail API credentials from AWS Secrets Manager
    """
    try:
        response = secretsmanager.get_secret_value(
            SecretId=GMAIL_CREDENTIALS_SECRET
        )
        
        secret = json.loads(response['SecretString'])
        return secret
    
    except Exception as e:
        logger.error(f"Error retrieving Gmail credentials: {str(e)}")
        raise

def find_available_interview_slots(hiring_manager_email, technical_staff_email):
    """
    Find available interview slots for the hiring manager and technical staff
    In a real implementation, this would use the Gmail API to check calendars
    For this example, we'll generate some sample slots
    """
    # Start from tomorrow
    start_date = datetime.now() + timedelta(days=1)
    
    # Generate 3 available slots in the next week
    available_slots = []
    for i in range(3):
        interview_date = start_date + timedelta(days=i+1)
        
        # Generate a morning slot (9-11 AM)
        morning_hour = random.randint(9, 11)
        morning_slot = datetime(
            interview_date.year, 
            interview_date.month, 
            interview_date.day, 
            morning_hour, 
            0, 0
        )
        
        # Generate an afternoon slot (1-4 PM)
        afternoon_hour = random.randint(13, 16)
        afternoon_slot = datetime(
            interview_date.year, 
            interview_date.month, 
            interview_date.day, 
            afternoon_hour, 
            0, 0
        )
        
        available_slots.extend([morning_slot, afternoon_slot])
    
    # Format the slots for display
    formatted_slots = []
    for slot in available_slots:
        formatted_slots.append({
            'datetime': slot,
            'formatted': slot.strftime('%A, %B %d, %Y at %I:%M %p')
        })
    
    return formatted_slots

def send_interview_invitation(candidate_data, interview_slot, hiring_manager_email, technical_staff_email):
    """
    Send interview invitation emails to the candidate, hiring manager, and technical staff
    """
    try:
        # Get candidate information
        candidate_name = candidate_data.get('name', 'Candidate')
        candidate_email = candidate_data.get('email', '')
        
        if not candidate_email:
            raise ValueError(f"No email found for candidate {candidate_data.get('id')}")
        
        # Format the interview date and time
        interview_datetime = interview_slot['formatted']
        
        # Create the email content
        subject = f"Interview Invitation: {candidate_name} - Technical Interview"
        
        # Email body for the candidate
        candidate_body = f"""
        Dear {candidate_name},
        
        Thank you for your interest in our company and for participating in the phone screening.
        
        We are pleased to invite you to the next stage of our interview process. Your interview has been scheduled for:
        
        Date and Time: {interview_datetime}
        
        The interview will be conducted via video conference. You will receive a calendar invitation with the meeting link shortly.
        
        If you have any questions or need to reschedule, please reply to this email.
        
        We look forward to speaking with you!
        
        Best regards,
        Recruiting Team
        """
        
        # Email body for the hiring manager and technical staff
        staff_body = f"""
        Hello,
        
        An interview has been scheduled with {candidate_name} for a technical position.
        
        Date and Time: {interview_datetime}
        
        The candidate's resume and phone screening results are attached for your review.
        
        Please let me know if you have any questions or if you need to reschedule.
        
        Best regards,
        Recruiting Team
        """
        
        # Send email to candidate
        send_email(candidate_email, subject, candidate_body)
        
        # Send email to hiring manager
        send_email(hiring_manager_email, subject, staff_body)
        
        # Send email to technical staff
        send_email(technical_staff_email, subject, staff_body)
        
        return True
    
    except Exception as e:
        logger.error(f"Error sending interview invitation: {str(e)}")
        raise

def send_email(recipient, subject, body):
    """
    Send an email using Amazon SES
    """
    try:
        # Create a multipart message
        msg = MIMEMultipart()
        msg['Subject'] = subject
        msg['From'] = "recruiting@example.com"  # Replace with your verified SES sender
        msg['To'] = recipient
        
        # Attach the body as plain text
        msg.attach(MIMEText(body, 'plain'))
        
        # Send the email using Amazon SES
        response = ses.send_raw_email(
            Source=msg['From'],
            Destinations=[recipient],
            RawMessage={'Data': msg.as_string()}
        )
        
        logger.info(f"Email sent to {recipient}, MessageId: {response['MessageId']}")
        return response['MessageId']
    
    except Exception as e:
        logger.error(f"Error sending email: {str(e)}")
        raise

def update_candidate_interview(candidate_id, interview_slot, hiring_manager_email, technical_staff_email):
    """
    Update the candidate's record with interview details
    """
    try:
        update_expression = """
        SET interview = :interview,
            status = :status
        """
        
        expression_values = {
            ':interview': {
                'datetime': interview_slot['formatted'],
                'hiringManager': hiring_manager_email,
                'technicalStaff': technical_staff_email,
                'status': 'SCHEDULED',
                'timestamp': int(time.time())
            },
            ':status': 'INTERVIEW_SCHEDULED'
        }
        
        candidate_table.update_item(
            Key={'id': candidate_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values
        )
        
        logger.info(f"Updated interview details for candidate {candidate_id}")
        return True
    
    except Exception as e:
        logger.error(f"Error updating interview details: {str(e)}")
        return False

def lambda_handler(event, context):
    """
    Lambda handler for scheduling interviews
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Extract candidate ID and job ID from event
        if 'candidateId' not in event:
            raise ValueError("Missing required parameter: candidateId")
        
        candidate_id = event['candidateId']
        
        # Get the candidate data
        candidate_data = get_candidate_data(candidate_id)
        if not candidate_data:
            raise ValueError(f"No data found for candidate {candidate_id}")
        
        # For this example, we'll use hardcoded email addresses
        # In a real implementation, these would come from configuration or the event
        hiring_manager_email = "hiring_manager@example.com"
        technical_staff_email = "tech_staff@example.com"
        
        # Find available interview slots
        available_slots = find_available_interview_slots(hiring_manager_email, technical_staff_email)
        
        if not available_slots:
            raise ValueError("No available interview slots found")
        
        # Select the first available slot
        selected_slot = available_slots[0]
        
        # Send the interview invitation
        send_interview_invitation(candidate_data, selected_slot, hiring_manager_email, technical_staff_email)
        
        # Update the candidate's record
        update_candidate_interview(candidate_id, selected_slot, hiring_manager_email, technical_staff_email)
        
        return {
            'statusCode': 200,
            'candidateId': candidate_id,
            'interviewScheduled': True,
            'interviewDateTime': selected_slot['formatted'],
            'hiringManager': hiring_manager_email,
            'technicalStaff': technical_staff_email
        }
    
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'error': str(e),
            'interviewScheduled': False
        }