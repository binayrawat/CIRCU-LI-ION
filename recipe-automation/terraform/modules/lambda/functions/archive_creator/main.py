import boto3
import os
import zipfile
import io

s3 = boto3.client('s3')
RECIPE_BUCKET = os.environ['RECIPE_BUCKET']
ARCHIVE_BUCKET = os.environ['ARCHIVE_BUCKET']

def handler(event, context):
    try:
        # Get the list of files to archive
        files_to_archive = event.get('files', [])
        archive_name = event.get('archive_name', 'recipe_archive.zip')
        
        # Create in-memory zip file
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            for file_key in files_to_archive:
                # Download file from recipes bucket
                file_obj = s3.get_object(Bucket=RECIPE_BUCKET, Key=file_key)
                file_content = file_obj['Body'].read()
                
                # Add to zip
                zip_file.writestr(os.path.basename(file_key), file_content)
        
        # Upload zip to archive bucket
        zip_buffer.seek(0)
        archive_key = f'archives/{archive_name}'
        s3.put_object(
            Bucket=ARCHIVE_BUCKET,
            Key=archive_key,
            Body=zip_buffer.getvalue()
        )
        
        return {
            'statusCode': 200,
            'body': {
                'message': 'Archive created successfully',
                'archive_bucket': ARCHIVE_BUCKET,
                'archive_key': archive_key
            }
        }
        
    except Exception as e:
        print(f"Error creating archive: {str(e)}")
        return {
            'statusCode': 500,
            'body': {'error': str(e)}
        } 