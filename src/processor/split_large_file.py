import boto3
import os
import json
from typing import Dict, Any, List
import math

class FileSplitter:
    def __init__(self):
        self.s3 = boto3.client('s3')
        self.chunk_size = 50 * 1024 * 1024  # 50MB chunks (to stay well under 512MB limit)
        self.buffer_size = 5 * 1024 * 1024  # 5MB buffer for streaming

    def split_file(self, bucket: str, key: str) -> List[Dict[str, Any]]:
        """Split large file into chunk metadata"""
        try:
            # Get file size without downloading
            response = self.s3.head_object(Bucket=bucket, Key=key)
            file_size = response['ContentLength']
            
            # Calculate chunks
            total_chunks = math.ceil(file_size / self.chunk_size)
            chunks_metadata = []
            
            for i in range(total_chunks):
                chunk_start = i * self.chunk_size
                chunk_end = min((i + 1) * self.chunk_size - 1, file_size - 1)
                
                chunks_metadata.append({
                    'chunk_number': i,
                    'start_byte': chunk_start,
                    'end_byte': chunk_end,
                    'size': chunk_end - chunk_start + 1,
                    'source_key': key
                })
            
            return chunks_metadata

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        record = event['Records'][0]['s3']
        bucket = record['bucket']['name']
        key = record['object']['key']
        
        if not key.startswith('uploads/'):
            return {
                'statusCode': 200,
                'body': 'Not an upload file, skipping'
            }
        
        splitter = FileSplitter()
        chunks_metadata = splitter.split_file(bucket, key)
        
        # Start Step Function
        sfn = boto3.client('stepfunctions')
        sfn.start_execution(
            stateMachineArn=os.environ['STEP_FUNCTION_ARN'],
            input=json.dumps({
                'bucket': bucket,
                'chunks_metadata': chunks_metadata
            })
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Processing started',
                'chunks': len(chunks_metadata)
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        } 