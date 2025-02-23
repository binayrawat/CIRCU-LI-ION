import boto3
import os
import zipfile
from typing import Dict, Any
from io import BytesIO

class StreamingZipper:
    def __init__(self):
        self.s3 = boto3.client('s3')
        self.buffer_size = 5 * 1024 * 1024  # 5MB buffer

    def stream_zip_chunk(self, bucket: str, chunk_metadata: Dict[str, Any]) -> str:
        """Stream and zip a chunk without storing entire file"""
        try:
            # Create a buffer for the zip
            zip_buffer = BytesIO()
            
            with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
                # Stream the chunk from S3
                response = self.s3.get_object(
                    Bucket=bucket,
                    Key=chunk_metadata['source_key'],
                    Range=f"bytes={chunk_metadata['start_byte']}-{chunk_metadata['end_byte']}"
                )
                
                # Create a file in the zip with streaming
                with zip_file.open(f"chunk_{chunk_metadata['chunk_number']}", 'w') as chunk_file:
                    stream = response['Body']
                    while True:
                        data = stream.read(self.buffer_size)
                        if not data:
                            break
                        chunk_file.write(data)
            
            # Upload the zipped chunk
            zip_key = f"zipped_chunks/chunk_{chunk_metadata['chunk_number']}.zip"
            zip_buffer.seek(0)
            self.s3.upload_fileobj(zip_buffer, bucket, zip_key)
            
            return zip_key
            
        except Exception as e:
            raise Exception(f"Error streaming chunk: {str(e)}")

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        bucket = event['bucket']
        chunk_metadata = event['chunk_metadata']
        
        zipper = StreamingZipper()
        zip_key = zipper.stream_zip_chunk(bucket, chunk_metadata)
        
        return {
            'statusCode': 200,
            'body': {
                'bucket': bucket,
                'zip_key': zip_key,
                'chunk_number': chunk_metadata['chunk_number']
            }
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': {'error': str(e)}
        } 