import boto3
import click
import os
import logging
from boto3.dynamodb.conditions import Key

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_auth_token(cognito_client, user_pool_id, client_id, username, password):
    try:
        response = cognito_client.initiate_auth(
            ClientId=client_id,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password
            }
        )
        return response['AuthenticationResult']['IdToken']
    except Exception as e:
        logger.error(f"Authentication failed: {str(e)}")
        raise

@click.command()
@click.option('--file', required=True, help='Recipe file to upload')
@click.option('--bucket', required=True, help='Target S3 bucket')
@click.option('--username', required=True, help='Cognito username')
@click.option('--password', required=True, help='Cognito password')
def upload_recipe(file, bucket, username, password):
    """Upload a recipe file to S3 with authentication"""
    
    if not os.path.exists(file):
        logger.error(f"File not found: {file}")
        return
    
    try:
        # Authenticate
        cognito = boto3.client('cognito-idp')
        token = get_auth_token(
            cognito,
            os.environ['COGNITO_USER_POOL_ID'],
            os.environ['COGNITO_CLIENT_ID'],
            username,
            password
        )
        
        # Upload to S3
        s3 = boto3.client('s3')
        logger.info(f"Uploading {file} to {bucket}")
        key = f'recipes/input/{os.path.basename(file)}'
        s3.upload_file(file, bucket, key)
        
        logger.info(f"Successfully uploaded {file}")
        
    except Exception as e:
        logger.error(f"Upload failed: {str(e)}")
        raise

if __name__ == '__main__':
    upload_recipe() 