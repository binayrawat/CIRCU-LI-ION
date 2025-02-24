import json
import os
import boto3
from datetime import datetime

def lambda_handler(event, context):
    """
    Create archives of processed recipes.
    
    Args:
        event: Lambda event
        context: Lambda context
    
    Returns:
        dict: Archive creation result
    """
    s3_client = boto3.client('s3')
    
    try:
        recipe_bucket = os.environ['RECIPE_BUCKET']
        archive_bucket = os.environ['ARCHIVE_BUCKET']
        
        # List processed recipes
        response = s3_client.list_objects_v2(
            Bucket=recipe_bucket,
            Prefix='processed/'
        )
        
        if 'Contents' not in response:
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'No recipes to archive'
                })
            }
        
        # Create archive
        archive_data = {
            'recipes': [],
            'archive_date': datetime.utcnow().isoformat(),
            'environment': os.environ['ENVIRONMENT']
        }
        
        for obj in response['Contents']:
            # Get recipe content
            recipe_response = s3_client.get_object(
                Bucket=recipe_bucket,
                Key=obj['Key']
            )
            recipe_content = json.loads(recipe_response['Body'].read().decode('utf-8'))
            archive_data['recipes'].append(recipe_content)
        
        # Save archive
        archive_key = f"archives/{datetime.utcnow().strftime('%Y-%m-%d')}/recipes.json"
        s3_client.put_object(
            Bucket=archive_bucket,
            Key=archive_key,
            Body=json.dumps(archive_data, indent=2),
            ContentType='application/json'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Archive created successfully',
                'archive_key': archive_key,
                'recipe_count': len(archive_data['recipes'])
            })
        }
        
    except Exception as e:
        print(f"Error creating archive: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error creating archive',
                'error': str(e)
            })
        } 