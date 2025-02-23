import pytest
from process import RecipeProcessor
import os
import boto3
from moto import mock_s3

@pytest.fixture
def processor():
    return RecipeProcessor()

@pytest.fixture
def mock_s3_bucket():
    with mock_s3():
        s3 = boto3.client('s3')
        s3.create_bucket(Bucket='test-bucket')
        yield s3

def test_process_large_file(processor, tmp_path):
    # Create test file
    input_file = tmp_path / "test.txt"
    input_file.write_bytes(b"test" * 1000)
    
    output_file = tmp_path / "output.zip"
    
    # Process file
    processor.process_large_file(str(input_file), str(output_file))
    
    # Verify output
    assert output_file.exists()
    assert output_file.stat().st_size > 0

def test_upload_file(processor, mock_s3_bucket, tmp_path):
    test_file = tmp_path / "test.txt"
    test_file.write_text("test")
    
    processor.upload_file(str(test_file), "test.txt")
    
    # Verify upload
    objects = mock_s3_bucket.list_objects(Bucket='test-bucket')
    assert len(objects.get('Contents', [])) == 1 