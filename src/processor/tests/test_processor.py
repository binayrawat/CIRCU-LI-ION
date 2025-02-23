import pytest
import boto3
import json
from moto import mock_s3
from split_large_file import FileSplitter, lambda_handler as split_handler
from stream_zip_chunk import StreamingZipper, lambda_handler as zip_handler
from stream_merge import StreamingMerger, lambda_handler as merge_handler

@pytest.fixture
def mock_s3_bucket():
    with mock_s3():
        s3 = boto3.client('s3')
        s3.create_bucket(Bucket='test-bucket')
        yield s3

@pytest.fixture
def mock_event():
    return {
        'Records': [{
            's3': {
                'bucket': {'name': 'test-bucket'},
                'object': {'key': 'uploads/test.txt'}
            }
        }]
    }

def test_file_splitter(mock_s3_bucket):
    # Create test file in S3
    mock_s3_bucket.put_object(
        Bucket='test-bucket',
        Key='uploads/test.txt',
        Body=b'test' * 1000
    )
    
    splitter = FileSplitter()
    chunks = splitter.split_file('test-bucket', 'uploads/test.txt')
    
    assert len(chunks) > 0
    assert all('chunk_number' in chunk for chunk in chunks)

def test_streaming_zipper(mock_s3_bucket):
    chunk_metadata = {
        'chunk_number': 0,
        'start_byte': 0,
        'end_byte': 99,
        'source_key': 'uploads/test.txt'
    }
    
    # Create test file
    mock_s3_bucket.put_object(
        Bucket='test-bucket',
        Key='uploads/test.txt',
        Body=b'test' * 25
    )
    
    zipper = StreamingZipper()
    zip_key = zipper.stream_zip_chunk('test-bucket', chunk_metadata)
    
    assert zip_key.startswith('zipped_chunks/') 