import json
import os
import pytest
from unittest.mock import MagicMock, patch
from archive_creator.index import lambda_handler

@pytest.fixture
def mock_s3():
    with patch('boto3.client') as mock_client:
        s3 = MagicMock()
        mock_client.return_value = s3
        yield s3

def test_successful_archive_creation(mock_s3):
    # Mock S3 responses
    mock_s3.list_objects_v2.return_value = {
        'Contents': [
            {'Key': 'processed/recipe1.json'},
            {'Key': 'processed/recipe2.json'}
        ]
    }
    mock_s3.get_object.return_value = {
        'Body': MagicMock(read=lambda: json.dumps({'name': 'Test Recipe'}).encode())
    }
    
    # Set environment variables
    os.environ['ENVIRONMENT'] = 'test'
    os.environ['RECIPE_BUCKET'] = 'test-recipe-bucket'
    os.environ['ARCHIVE_BUCKET'] = 'test-archive-bucket'
    
    # Call handler
    response = lambda_handler({}, None)
    
    # Verify response
    assert response['statusCode'] == 200
    assert 'Archive created successfully' in response['body']
    
    # Verify S3 interactions
    mock_s3.list_objects_v2.assert_called_once()
    assert mock_s3.get_object.call_count == 2
    mock_s3.put_object.assert_called_once()

def test_no_recipes_to_archive(mock_s3):
    # Mock empty S3 response
    mock_s3.list_objects_v2.return_value = {}
    
    # Set environment variables
    os.environ['ENVIRONMENT'] = 'test'
    os.environ['RECIPE_BUCKET'] = 'test-recipe-bucket'
    os.environ['ARCHIVE_BUCKET'] = 'test-archive-bucket'
    
    # Call handler
    response = lambda_handler({}, None)
    
    # Verify response
    assert response['statusCode'] == 200
    assert 'No recipes to archive' in response['body'] 