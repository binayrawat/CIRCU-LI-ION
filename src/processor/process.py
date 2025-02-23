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
    """
    Process recipe files:
    1. Download from S3
    2. Validate recipe format
    3. Create versioned ZIP archive
    4. Upload back to S3
    """
    s3 = boto3.client('s3')
    
    try:
        # Download input file
        logger.info(f"Downloading {input_key} from {bucket}")
        local_file = f'/tmp/{os.path.basename(input_key)}'
        s3.download_file(bucket, input_key, local_file)
        
        # Validate if it's a JSON recipe
        if input_key.endswith('.json'):
            with open(local_file, 'r') as f:
                recipe_data = json.load(f)
                validate_recipe(recipe_data)
                logger.info("Recipe validation successful")
        
        # Create versioned ZIP archive
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        zip_filename = f'/tmp/recipe_archive_{timestamp}.zip'
        
        logger.info("Creating ZIP archive")
        with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # Add the main file
            zipf.write(local_file, os.path.basename(input_key))
            
            # Add metadata if it's a JSON recipe
            if input_key.endswith('.json'):
                metadata = {
                    "processed_timestamp": timestamp,
                    "recipe_id": recipe_data.get('recipe_id'),
                    "version": recipe_data.get('version')
                }
                metadata_file = '/tmp/metadata.json'
                with open(metadata_file, 'w') as f:
                    json.dump(metadata, f)
                zipf.write(metadata_file, 'metadata.json')
        
        # Upload result
        logger.info(f"Uploading archive to {output_key}")
        s3.upload_file(zip_filename, bucket, output_key)
        
        # Add tags to the S3 object
        s3.put_object_tagging(
            Bucket=bucket,
            Key=output_key,
            Tagging={
                'TagSet': [
                    {
                        'Key': 'ProcessedTimestamp',
                        'Value': timestamp
                    },
                    {
                        'Key': 'RecipeType',
                        'Value': 'json' if input_key.endswith('.json') else 'binary'
                    }
                ]
            }
        )
        
        return True
        
    except Exception as e:
        logger.error(f"Error processing recipe: {str(e)}")
        raise
        
    finally:
        # Cleanup
        files_to_clean = [
            '/tmp/metadata.json',
            local_file,
            zip_filename
        ]
        for file in files_to_clean:
            if os.path.exists(file):
                os.remove(file)

if __name__ == "__main__":
    bucket = os.environ['BUCKET_NAME']
    input_key = os.environ['INPUT_KEY']
    output_key = os.environ['OUTPUT_KEY']
    process_recipe(bucket, input_key, output_key) 