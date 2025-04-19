import json
import boto3
import os
import logging
from decimal import Decimal
from boto3.dynamodb.conditions import Key

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb')

# Get environment variables
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
candidate_table = dynamodb.Table(DYNAMODB_TABLE)

# JSON helper class for Decimal types
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def get_candidates_for_job(job_id):
    """
    Retrieve all screened candidates for a specific job
    """
    try:
        response = candidate_table.query(
            IndexName='JobRankingIndex',
            KeyConditionExpression=Key('jobId').eq(job_id)
        )
        
        if 'Items' not in response or not response['Items']:
            logger.warning(f"No candidates found for job {job_id}")
            return []
        
        # Filter for candidates that have been screened
        screened_candidates = [
            item for item in response['Items'] 
            if item.get('status') == 'SCREENED' and 'screening' in item
        ]
        
        return screened_candidates
    
    except Exception as e:
        logger.error(f"Error retrieving candidates: {str(e)}")
        return []

def rank_candidates(candidates):
    """
    Rank candidates based on their screening scores
    """
    try:
        # Sort candidates based on screening score (descending)
        sorted_candidates = sorted(
            candidates,
            key=lambda x: x.get('screening', {}).get('score', 0),
            reverse=True
        )
        
        # Calculate total number of candidates
        total_candidates = len(sorted_candidates)
        
        # Mark whether each candidate is in the top 5%
        top_threshold = max(1, int(total_candidates * 0.05))  # At least 1 candidate
        
        for i, candidate in enumerate(sorted_candidates):
            # Calculate ranking (1-based index)
            ranking = i + 1
            
            # Determine if candidate is in top 5%
            is_top_candidate = ranking <= top_threshold
            
            # Update candidate record with ranking
            candidate_table.update_item(
                Key={'id': candidate['id']},
                UpdateExpression="SET ranking = :ranking, isTopCandidate = :isTop, status = :status",
                ExpressionAttributeValues={
                    ':ranking': Decimal(str(ranking)),
                    ':isTop': is_top_candidate,
                    ':status': 'RANKED'
                }
            )
            
            # Update the candidate object for return value
            candidate['ranking'] = ranking
            candidate['isTopCandidate'] = is_top_candidate
        
        return sorted_candidates
    
    except Exception as e:
        logger.error(f"Error ranking candidates: {str(e)}")
        raise

def lambda_handler(event, context):
    """
    Lambda handler for ranking candidates
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Extract job ID from event
        if 'jobId' not in event:
            raise ValueError("Missing required parameter: jobId")
        
        job_id = event['jobId']
        
        # Get all candidates for the job
        candidates = get_candidates_for_job(job_id)
        
        # Rank the candidates
        ranked_candidates = rank_candidates(candidates)
        
        # Determine if the current candidate is in the top 5%
        current_candidate_id = event.get('candidateId')
        is_top_candidate = False
        
        if current_candidate_id:
            for candidate in ranked_candidates:
                if candidate['id'] == current_candidate_id:
                    is_top_candidate = candidate.get('isTopCandidate', False)
                    break
        
        # Return the ranking results
        return {
            'statusCode': 200,
            'jobId': job_id,
            'candidateId': current_candidate_id,
            'totalCandidates': len(ranked_candidates),
            'topCandidates': [c for c in ranked_candidates if c.get('isTopCandidate', False)],
            'isTopCandidate': is_top_candidate,
            'ranked': True
        }
    
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'error': str(e),
            'ranked': False
        }