import json
import boto3
from datetime import datetime
import io
import zipfile

def format_size(size_bytes):
    """Convert bytes to human readable format"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} TB"

def lambda_handler(event, context):
    print("Starting merge_results Lambda")
    start_time = datetime.utcnow()
    s3_client = boto3.client('s3')
    
    try:
        # Get first chunk for bucket/key info
        first_chunk = event[0]
        bucket = first_chunk.get('bucket')
        original_key = first_chunk.get('original_key')
        
        if not bucket or not original_key:
            raise ValueError("Could not determine output location from chunk results")
        
        # Get original file size
        original_file = s3_client.head_object(Bucket=bucket, Key=original_key)
        original_size = original_file['ContentLength']
        
        # Create ZIP file with all data
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            # Add processing summary
            summary = {
                'original_file': {
                    'name': original_key.split('/')[-1],
                    'size': format_size(original_size),
                    'path': f's3://{bucket}/{original_key}'
                },
                'processing': {
                    'start_time': start_time.isoformat(),
                    'total_chunks': len(event),
                    'total_objects': sum(chunk.get('objects_found', 0) for chunk in event)
                },
                'chunks': [
                    {
                        'chunk_number': chunk['chunk_number'],
                        'objects_found': chunk.get('objects_found', 0),
                        'byte_range': chunk.get('byte_range', {})
                    }
                    for chunk in sorted(event, key=lambda x: x['chunk_number'])
                ]
            }
            zip_file.writestr('summary.json', json.dumps(summary, indent=2))
            
            # Add each chunk's data
            for chunk in sorted(event, key=lambda x: x['chunk_number']):
                try:
                    # Get chunk data from S3
                    data_response = s3_client.get_object(
                        Bucket=bucket,
                        Key=chunk['data_key']
                    )
                    chunk_data = data_response['Body'].read().decode('utf-8')
                    
                    # Add to ZIP with chunk number in filename
                    filename = f'chunk_{chunk["chunk_number"]:03d}.json'
                    zip_file.writestr(filename, chunk_data)
                    
                except Exception as e:
                    print(f"Error adding chunk {chunk['chunk_number']}: {str(e)}")
                    continue
        
        # Save the final ZIP file
        zip_key = original_key.replace('uploads/', 'processed/').replace('.json', '_processed.zip')
        print(f"Saving final ZIP to {bucket}/{zip_key}")
        zip_buffer.seek(0)
        s3_client.put_object(
            Bucket=bucket,
            Key=zip_key,
            Body=zip_buffer.getvalue()
        )
        
        return {
            'statusCode': 200,
            'message': 'Processing complete',
            'output': f's3://{bucket}/{zip_key}'
        }
        
    except Exception as e:
        print(f"Error in merge_results: {str(e)}")
        raise
