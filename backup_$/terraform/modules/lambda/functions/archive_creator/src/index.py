import json
import boto3
from datetime import datetime

def lambda_handler(event, context):
    s3_client = boto3.client('s3')
    try:
        # Get bucket and key from event
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        
        # Move to archive
        archive_key = key.replace('processed/', 'archive/')
        s3_client.copy_object(
            Bucket=bucket,
            Key=archive_key,
            CopySource={'Bucket': bucket, 'Key': key}
        )
        
        # Delete from processed
        s3_client.delete_object(Bucket=bucket, Key=key)
        
        return {
            'statusCode': 200,
            'message': 'Recipe archived successfully',
            'file': {
                'bucket': bucket,
                'key': archive_key
            }
        }
    except Exception as e:
        print(f"Error archiving recipe: {str(e)}")
        raise
