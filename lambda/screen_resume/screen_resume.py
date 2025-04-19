import json
import boto3
import os
import logging
from decimal import Decimal

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock = boto3.client('bedrock-runtime')
dynamodb = boto3.resource('dynamodb')

# Get environment variables
BEDROCK_MODEL_ID = os.environ['BEDROCK_MODEL_ID']
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
candidate_table = dynamodb.Table(DYNAMODB_TABLE)

# JSON helper class for Decimal types
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def get_resume_data(candidate_id):
    """
    Retrieve resume data from DynamoDB
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
        logger.error(f"Error retrieving resume data: {str(e)}")
        return None

def evaluate_resume_with_bedrock(resume_text, job_id):
    """
    Use Amazon Bedrock to evaluate a resume for job fit
    """
    try:
        # Get job description for the given job_id
        # This is a placeholder - in a real implementation, you would retrieve 
        # the job description from a database or other source
        job_description = get_job_description(job_id)
        
        # Construct the prompt for Bedrock
        prompt = f"""
        You are an expert HR recruiter with deep experience in technical recruitment.
        
        JOB DESCRIPTION:
        {job_description}
        
        CANDIDATE RESUME:
        {resume_text}
        
        Please evaluate this resume against the job description and provide:
        
        1. A score from 0 to 100 representing how well the candidate matches the job requirements
        2. A brief assessment (maximum 300 words) highlighting strengths and weaknesses
        3. Key skills that match the job requirements
        4. Key skills that are missing for the job
        5. A recommendation (PROCEED or REJECT) on whether to move this candidate to the phone interview stage
        
        Format your response as a JSON object with the following structure:
        {{
            "score": <number>,
            "assessment": "<text>",
            "matching_skills": ["<skill1>", "<skill2>", ...],
            "missing_skills": ["<skill1>", "<skill2>", ...],
            "recommendation": "<PROCEED or REJECT>"
        }}
        """
        
        # Call Bedrock with the prompt
        response = bedrock.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "temperature": 0.2,
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
        assistant_response = response_body['content'][0]['text']
        
        try:
            # Extract the JSON part from the response
            json_str = assistant_response.strip()
            if json_str.startswith('```json'):
                json_str = json_str[7:]
            if json_str.endswith('```'):
                json_str = json_str[:-3]
            
            evaluation = json.loads(json_str.strip())
            return evaluation
        
        except json.JSONDecodeError as e:
            logger.error(f"Error parsing JSON from Bedrock response: {str(e)}")
            logger.error(f"Raw response: {assistant_response}")
            
            # Fallback: Create a simple evaluation object
            return {
                "score": 0,
                "assessment": "Error processing resume",
                "matching_skills": [],
                "missing_skills": [],
                "recommendation": "REJECT"
            }
    
    except Exception as e:
        logger.error(f"Error evaluating resume with Bedrock: {str(e)}")
        raise

def get_job_description(job_id):
    """
    Get job description for a given job ID
    This is a placeholder function - in a real implementation,
    you would retrieve this from a database
    """
    # Sample job descriptions for different job IDs
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
        
        "data-scientist": """
        Data Scientist
        
        Responsibilities:
        - Develop and implement advanced analytics models and algorithms
        - Process, cleanse, and validate data for analysis
        - Build and optimize classifiers using machine learning techniques
        - Identify patterns and insights in large datasets
        - Present findings to stakeholders and recommend solutions
        
        Requirements:
        - Master's or PhD in Data Science, Computer Science, Statistics, or related field
        - 2+ years of experience in data science or related field
        - Strong programming skills in Python, R, or similar languages
        - Experience with machine learning libraries (e.g., TensorFlow, PyTorch, scikit-learn)
        - Knowledge of data visualization techniques and tools
        - Excellent problem-solving and analytical thinking skills
        - Ability to communicate complex findings to technical and non-technical audiences
        """,
        
        "devops-engineer": """
        DevOps Engineer
        
        Responsibilities:
        - Build and maintain CI/CD pipelines
        - Implement and manage infrastructure as code using tools like Terraform
        - Monitor system performance and troubleshoot issues
        - Automate deployment processes and system configurations
        - Collaborate with development and operations teams
        
        Requirements:
        - Bachelor's degree in Computer Science or related field
        - 3+ years of experience in DevOps or related roles
        - Strong knowledge of Linux/Unix systems administration
        - Experience with containerization technologies (Docker, Kubernetes)
        - Proficiency in scripting languages (Python, Bash, etc.)
        - Experience with CI/CD tools (Jenkins, GitLab CI, GitHub Actions)
        - Knowledge of cloud platforms (AWS, Azure, or GCP)
        """
    }
    
    # Return the job description for the given job ID, or a default one if not found
    return job_descriptions.get(job_id, """
    Generic Technical Position
    
    Responsibilities:
    - Contribute to technical projects and initiatives
    - Collaborate with team members and stakeholders
    - Ensure high-quality deliverables and outcomes
    
    Requirements:
    - Technical degree or equivalent experience
    - Strong problem-solving skills
    - Ability to work in a collaborative environment
    - Good communication skills
    """)

def update_candidate_screening(candidate_id, evaluation):
    """
    Update the candidate's record with screening results
    """
    try:
        # Convert to Decimal for DynamoDB
        if isinstance(evaluation.get('score'), (int, float)):
            evaluation['score'] = Decimal(str(evaluation['score']))
        
        update_expression = "SET screening = :screening, status = :status"
        expression_values = {
            ':screening': evaluation,
            ':status': 'SCREENED'
        }
        
        candidate_table.update_item(
            Key={'id': candidate_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values
        )
        
        logger.info(f"Updated screening results for candidate {candidate_id}")
        return True
    
    except Exception as e:
        logger.error(f"Error updating screening results: {str(e)}")
        return False

def lambda_handler(event, context):
    """
    Lambda handler for screening resumes
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Extract candidate ID and job ID from event
        if 'candidateId' not in event or 'jobId' not in event:
            raise ValueError("Missing required parameters: candidateId and jobId")
        
        candidate_id = event['candidateId']
        job_id = event['jobId']
        
        # Get the resume data
        resume_data = get_resume_data(candidate_id)
        if not resume_data or 'resumeText' not in resume_data:
            raise ValueError(f"No resume text found for candidate {candidate_id}")
        
        # Evaluate the resume using Bedrock
        evaluation = evaluate_resume_with_bedrock(resume_data['resumeText'], job_id)
        
        # Update the candidate's record with screening results
        update_candidate_screening(candidate_id, evaluation)
        
        # Return the evaluation results
        return {
            'statusCode': 200,
            'candidateId': candidate_id,
            'jobId': job_id,
            'evaluation': json.loads(json.dumps(evaluation, cls=DecimalEncoder)),
            'screened': True
        }
    
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'error': str(e),
            'screened': False
        }