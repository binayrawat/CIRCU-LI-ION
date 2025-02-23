import boto3
import os
from typing import Dict, Any, List
from io import BytesIO
import zipfile

class StreamingMerger:
    def __init__(self):
        self.s3 = boto3.client('s3')
        self.buffer_size = 5 * 1024 * 1024  # 5MB buffer

    def stream_merge(self, bucket: str, zip_keys: List[str], output_key: str) -> str:
        """Merge zips using streaming"""
        try:
            # Create output zip buffer
            output_buffer = BytesIO()
            
            with zipfile.ZipFile(output_buffer, 'w', zipfile.ZIP_DEFLATED) as output_zip:
                for zip_key in zip_keys:
                    # Stream each zip file
                    response = self.s3.get_object(Bucket=bucket, Key=zip_key)
                    zip_content = BytesIO(response['Body'].read())
                    
                    # Add contents to final zip
                    with zipfile.ZipFile(zip_content) as input_zip:
                        for name in input_zip.namelist():
                            with input_zip.open(name) as source, output_zip.open(name, 'w') as target:
                                while True:
                                    chunk = source.read(self.buffer_size)
                                    if not chunk:
                                        break
                                    target.write(chunk)
            
            # Upload final zip
            output_buffer.seek(0)
            self.s3.upload_fileobj(output_buffer, bucket, output_key)
            
            return output_key
            
        except Exception as e:
            raise Exception(f"Error merging: {str(e)}")

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        bucket = event['bucket']
        zip_keys = event['zip_keys']
        output_key = f"processed/final_{event['timestamp']}.zip"
        
        merger = StreamingMerger()
        final_key = merger.stream_merge(bucket, zip_keys, output_key)
        
        return {
            'statusCode': 200,
            'body': {
                'bucket': bucket,
                'final_key': final_key
            }
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': {'error': str(e)}
        } 