import boto3
import zipfile
import os
import json
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def validate_recipe(recipe_data):
    """Validate recipe format"""
    required_fields = ['recipe_id', 'version', 'steps']
    for field in required_fields:
        if field not in recipe_data:
            raise ValueError(f"Missing required field: {field}")
    
    for step in recipe_data['steps']:
        if not all(k in step for k in ['step_id', 'action', 'target']):
            raise ValueError("Invalid step format")

def process_recipe(bucket, input_key, output_key):
    """Process a recipe file"""
    s3 = boto3.client('s3')
    
    try:
        # Download input file
        logger.info(f"Downloading {input_key} from {bucket}")
        s3.download_file(bucket, input_key, '/tmp/input.file')
        
        # Create ZIP archive
        logger.info("Creating ZIP archive")
        with zipfile.ZipFile('/tmp/output.zip', 'w') as zipf:
            zipf.write('/tmp/input.file', os.path.basename(input_key))
        
        # Upload result with correct content type
        logger.info(f"Uploading result to {output_key}")
        s3.upload_file(
            '/tmp/output.zip',
            bucket,
            output_key,
            ExtraArgs={'ContentType': 'application/zip'}
        )
        
        return True
        
    except Exception as e:
        logger.error(f"Error processing recipe: {str(e)}")
        raise
        
    finally:
        # Cleanup
        if os.path.exists('/tmp/input.file'):
            os.remove('/tmp/input.file')
        if os.path.exists('/tmp/output.zip'):
            os.remove('/tmp/output.zip')

if __name__ == "__main__":
    bucket = os.environ['BUCKET_NAME']
    input_key = os.environ['INPUT_KEY']
    output_key = os.environ['OUTPUT_KEY']
    process_recipe(bucket, input_key, output_key) 