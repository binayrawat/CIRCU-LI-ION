import json
import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
    print("Starting split_file Lambda")
    s3_client = boto3.client('s3')
    sfn_client = boto3.client('stepfunctions')
    
    try:
        # Get bucket and key from event
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        print(f"Processing file: {bucket}/{key}")
        
        # Get file size
        response = s3_client.head_object(Bucket=bucket, Key=key)
        file_size = response['ContentLength']
        
        # Calculate chunk sizes (50MB per chunk)
        chunk_size = 50 * 1024 * 1024  # 50MB in bytes
        total_chunks = (file_size + chunk_size - 1) // chunk_size
        print(f"File size: {file_size} bytes, splitting into {total_chunks} chunks")
        
        # Create chunks info
        chunks = []
        for i in range(total_chunks):
            start_byte = i * chunk_size
            end_byte = min((i + 1) * chunk_size - 1, file_size - 1)
            chunks.append({
                'bucket': bucket,
                'key': key,
                'chunk_number': i,
                'start_byte': start_byte,
                'end_byte': end_byte,
                'total_chunks': total_chunks
            })
        
        # Start Step Function execution
        step_function_arn = os.environ['STEP_FUNCTION_ARN']
        print(f"Starting Step Function: {step_function_arn}")
        
        execution_input = {
            'chunks': chunks,
            'original_file': {
                'bucket': bucket,
                'key': key,
                'size': file_size
            }
        }
        
        print(f"Step Function input: {json.dumps(execution_input)}")
        sfn_response = sfn_client.start_execution(
            stateMachineArn=step_function_arn,
            input=json.dumps(execution_input)
        )
        print(f"Step Function started: {sfn_response['executionArn']}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'File split and Step Function started',
                'executionArn': sfn_response['executionArn'],
                'chunks': len(chunks)
            })
        }
        
    except Exception as e:
        print(f"Error in split_file Lambda: {str(e)}")
        raise
