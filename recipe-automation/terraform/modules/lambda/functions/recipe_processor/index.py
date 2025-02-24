import json
import os
import boto3
import zipfile
import io
from datetime import datetime

def process_chunk(data, chunk_number):
    """Process a chunk of the recipe data"""
    chunk_data = {
        'chunk_number': chunk_number,
        'processed_date': datetime.utcnow().isoformat(),
        'environment': os.environ['ENVIRONMENT'],
        'data': data
    }
    return chunk_data

def lambda_handler(event, context):
    """
    Process recipe files in chunks and create multiple ZIP files.
    """
    s3_client = boto3.client('s3')
    CHUNK_SIZE = 100 * 1024 * 1024  # 100MB chunks
    
    try:
        # Get bucket and key from event
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        
        # Get object size
        response = s3_client.head_object(Bucket=bucket, Key=key)
        file_size = response['ContentLength']
        
        # Calculate number of chunks needed
        num_chunks = (file_size + CHUNK_SIZE - 1) // CHUNK_SIZE
        
        print(f"Processing file of size {file_size} bytes in {num_chunks} chunks")
        
        # Process in chunks
        for i in range(num_chunks):
            start_byte = i * CHUNK_SIZE
            end_byte = min((i + 1) * CHUNK_SIZE - 1, file_size - 1)
            
            # Get chunk of data
            response = s3_client.get_object(
                Bucket=bucket,
                Key=key,
                Range=f'bytes={start_byte}-{end_byte}'
            )
            chunk_data = json.loads(response['Body'].read().decode('utf-8'))
            
            # Process chunk
            processed_chunk = process_chunk(chunk_data, i)
            
            # Create ZIP for this chunk
            zip_buffer = io.BytesIO()
            with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
                zip_file.writestr(
                    f'recipe_chunk_{i}.json',
                    json.dumps(processed_chunk)
                )
            
            # Upload chunk ZIP
            chunk_key = key.replace('uploads/', f'processed/chunks/').replace(
                '.json', f'_chunk_{i}.zip'
            )
            s3_client.put_object(
                Bucket=bucket,
                Key=chunk_key,
                Body=zip_buffer.getvalue()
            )
            
            print(f"Processed and uploaded chunk {i+1} of {num_chunks}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Recipe processed in {num_chunks} chunks',
                'source': key,
                'chunks': num_chunks
            })
        }
        
    except Exception as e:
        print(f"Error processing recipe: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error processing recipe',
                'error': str(e)
            })
        } 