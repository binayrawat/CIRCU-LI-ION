import json
import os
import pytest
from unittest.mock import MagicMock, patch
from recipe_processor.index import lambda_handler

@pytest.fixture
def s3_event():
    return {
        'Records': [{
            's3': {
                'bucket': {'name': 'test-bucket'},
                'object': {'key': 'uploads/test-recipe.json'}
            }
        }]
    }

@pytest.fixture
def mock_s3():
    with patch('boto3.client') as mock_client:
        s3 = MagicMock()
        mock_client.return_value = s3
        yield s3

def test_successful_processing(s3_event, mock_s3):
    # Mock S3 responses
    mock_s3.get_object.return_value = {
        'Body': MagicMock(read=lambda: json.dumps({'name': 'Test Recipe'}).encode())
    }
    
    # Set environment variables
    os.environ['ENVIRONMENT'] = 'test'
    
    # Call handler
    response = lambda_handler(s3_event, None)
    
    # Verify response
    assert response['statusCode'] == 200
    assert 'Recipe processed successfully' in response['body']
    
    # Verify S3 interactions
    mock_s3.get_object.assert_called_once()
    mock_s3.put_object.assert_called_once()

def test_error_handling(s3_event, mock_s3):
    # Mock S3 error
    mock_s3.get_object.side_effect = Exception('Test error')
    
    # Call handler
    response = lambda_handler(s3_event, None)
    
    # Verify error response
    assert response['statusCode'] == 500
    assert 'Error processing recipe' in response['body'] 