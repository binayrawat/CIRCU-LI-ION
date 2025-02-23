import pytest
import os
from src.processor.process import process_recipe
import zipfile

def test_process_recipe(s3):
    """Test recipe processing"""
    # Setup
    bucket = 'test-bucket'
    input_key = 'recipes/test.json'
    output_key = 'processed/test.json.zip'
    
    # Create test bucket with location constraint
    s3.create_bucket(
        Bucket=bucket,
        CreateBucketConfiguration={
            'LocationConstraint': 'us-west-2'
        }
    )
    
    # Upload test file
    s3.put_object(
        Bucket=bucket,
        Key=input_key,
        Body='{"test": "data"}'
    )
    
    # Process recipe
    result = process_recipe(bucket, input_key, output_key)
    
    # Verify
    assert result == True
    
    # Check if output exists and has correct content type
    response = s3.get_object(Bucket=bucket, Key=output_key)
    assert response['ContentType'] == 'application/zip'
    
    # Verify it's actually a ZIP file
    s3.download_file(bucket, output_key, '/tmp/test.zip')
    assert zipfile.is_zipfile('/tmp/test.zip')

def test_process_recipe_error(s3):
    """Test error handling"""
    with pytest.raises(Exception):
        process_recipe('nonexistent-bucket', 'bad-key', 'output-key') 