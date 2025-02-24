import json
import boto3
import os
from datetime import datetime

def extract_json_objects(text):
    """Extract valid JSON objects from text"""
    objects = []
    start = 0
    while True:
        try:
            start = text.find('{', start)
            if start == -1:
                break
                
            decoder = json.JSONDecoder()
            obj, end = decoder.raw_decode(text[start:])
            objects.append(obj)
            start = start + end
            
        except json.JSONDecodeError:
            start += 1
            continue
            
    return objects

def lambda_handler(event, context):
    print("Starting process_chunk Lambda")
    print(f"Received event: {json.dumps(event)}")
    s3_client = boto3.client('s3')
    
    try:
        # Get chunk info
        chunk_info = event
        bucket = chunk_info['bucket']
        key = chunk_info['key']
        chunk_number = chunk_info['chunk_number']
        start_byte = chunk_info['start_byte']
        end_byte = chunk_info['end_byte']
        
        print(f"Processing chunk {chunk_number} from {bucket}/{key}")
        
        # Get the chunk from S3
        response = s3_client.get_object(
            Bucket=bucket,
            Key=key,
            Range=f'bytes={start_byte}-{end_byte}'
        )
        chunk_text = response['Body'].read().decode('utf-8')
        
        # Extract JSON objects
        json_objects = extract_json_objects(chunk_text)
        print(f"Found {len(json_objects)} JSON objects in chunk")
        
        # Save the full data to S3
        data_key = key.replace('uploads/', 'processed/data/').replace(
            '.json', f'_chunk_{chunk_number}_data.json'
        )
        s3_client.put_object(
            Bucket=bucket,
            Key=data_key,
            Body=json.dumps(json_objects)
        )
        
        # Return only metadata (no large data)
        result = {
            'statusCode': 200,
            'chunk_number': chunk_number,
            'bucket': bucket,
            'data_key': data_key,
            'original_key': key,
            'objects_found': len(json_objects),
            'byte_range': {
                'start': start_byte,
                'end': end_byte
            }
        }
        
        print(f"Successfully processed chunk {chunk_number}")
        return result
        
    except Exception as e:
        print(f"Error processing chunk: {str(e)}")
        raise
