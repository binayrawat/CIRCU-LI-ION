import boto3
import json
import os
import logging
import zipfile
from io import BytesIO
from typing import Dict, Any
from concurrent.futures import ThreadPoolExecutor

# Configure logging based on environment
log_level = os.environ.get('LOG_LEVEL', 'INFO')
logging.basicConfig(level=log_level)
logger = logging.getLogger(__name__)

class RecipeProcessor:
    def __init__(self):
        self.s3 = boto3.client('s3')
        self.output_bucket = os.environ['OUTPUT_BUCKET']
        self.environment = os.environ.get('ENVIRONMENT', 'dev')
        self.chunk_size = 100 * 1024 * 1024  # 100MB chunks
        self.max_threads = 4

    def process_recipe(self, event: Dict[str, Any]) -> Dict[str, Any]:
        """Process recipe files and create ZIP archive"""
        try:
            # Extract event details
            bucket = event['Records'][0]['s3']['bucket']['name']
            key = event['Records'][0]['s3']['object']['key']
            
            logger.info(f"Processing recipe from {bucket}/{key}")
            
            # Download the recipe file
            response = self.s3.get_object(Bucket=bucket, Key=key)
            recipe_content = response['Body'].read()
            
            # Create ZIP archive
            output_zip = BytesIO()
            with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
                zipf.writestr('recipe.json', recipe_content)
            
            # Generate output key
            output_key = f"processed/{self.environment}/{key.split('/')[-1]}.zip"
            
            # Upload processed file
            self.s3.put_object(
                Bucket=self.output_bucket,
                Key=output_key,
                Body=output_zip.getvalue(),
                Metadata={
                    'environment': self.environment,
                    'original_file': key
                }
            )
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Recipe processed successfully',
                    'output': output_key,
                    'environment': self.environment
                })
            }
            
        except Exception as e:
            logger.error(f"Error processing recipe: {str(e)}")
            raise

    def process_large_file(self, input_path: str, output_path: str):
        """Process large file in chunks and create zip"""
        try:
            # 1. Split into chunks
            file_size = os.path.getsize(input_path)
            chunk_files = []
            
            with ThreadPoolExecutor(max_workers=self.max_threads) as executor:
                futures = []
                for i in range(0, file_size, self.chunk_size):
                    chunk_size = min(self.chunk_size, file_size - i)
                    futures.append(
                        executor.submit(
                            self.process_chunk, 
                            input_path, 
                            i, 
                            chunk_size, 
                            len(chunk_files)
                        )
                    )
                    chunk_files.append(f"/tmp/chunk_{len(chunk_files)}.zip")

                # Wait for all chunks to be processed
                for future in futures:
                    future.result()

            # 2. Combine chunks into final zip
            with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as final_zip:
                for chunk_file in chunk_files:
                    with zipfile.ZipFile(chunk_file, 'r') as chunk_zip:
                        for name in chunk_zip.namelist():
                            final_zip.writestr(name, chunk_zip.read(name))
                    os.remove(chunk_file)  # Cleanup chunk file

        except Exception as e:
            logger.error(f"Error processing file: {str(e)}")
            raise

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Lambda handler function"""
    processor = RecipeProcessor()
    return processor.process_recipe(event)