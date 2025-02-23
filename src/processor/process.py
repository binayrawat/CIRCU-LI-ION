import boto3
import click
import json
import os
import zipfile
from io import BytesIO
from datetime import datetime

def process_recipe(bucket: str, input_key: str, output_key: str) -> bool:
    """
    Process a recipe from S3
    
    Args:
        bucket (str): S3 bucket name
        input_key (str): Input file key
        output_key (str): Output file key
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Initialize S3 client
        s3 = boto3.client('s3')
        
        # Get the recipe file
        response = s3.get_object(Bucket=bucket, Key=input_key)
        recipe_data = json.loads(response['Body'].read().decode('utf-8'))
        
        # Process the recipe (add your processing logic here)
        processed_data = recipe_data
        
        # Create ZIP file in memory
        zip_buffer = BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            zip_file.writestr('recipe.json', json.dumps(processed_data))
        
        # Upload processed ZIP file
        s3.put_object(
            Bucket=bucket,
            Key=output_key,
            Body=zip_buffer.getvalue(),
            ContentType='application/zip'
        )
        
        return True
        
    except Exception as e:
        print(f"Error processing recipe: {e}")
        raise  # Re-raise the exception for proper error handling

@click.command()
@click.option('--bucket', required=True, help='S3 bucket name')
@click.option('--input-key', required=True, help='Input file key')
@click.option('--output-key', required=True, help='Output file key')
def main(bucket: str, input_key: str, output_key: str):
    """CLI interface for recipe processing"""
    success = process_recipe(bucket, input_key, output_key)
    if not success:
        exit(1)

if __name__ == "__main__":
    try:
        process_recipe()
    except Exception as e:
        print(f"Failed to process recipe: {e}")
        exit(1)