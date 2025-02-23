import boto3
import zipfile
import os
import logging


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def process_recipe(bucket, input_key, output_key):
    """Process a recipe file"""
    s3 = boto3.client("s3")
    try:
        logger.info(f"Downloading {input_key} from {bucket}")
        s3.download_file(bucket, input_key, "/tmp/input.file")
        logger.info("Creating ZIP archive")
        with zipfile.ZipFile("/tmp/output.zip", "w") as zipf:
            zipf.write("/tmp/input.file", os.path.basename(input_key))
        logger.info(f"Uploading result to {output_key}")
        s3.upload_file(
            "/tmp/output.zip",
            bucket,
            output_key,
            ExtraArgs={"ContentType": "application/zip"}
        )
        return True
    except Exception as e:
        logger.error(f"Error processing recipe: {str(e)}")
        raise
    finally:
        if os.path.exists("/tmp/input.file"):
            os.remove("/tmp/input.file")
        if os.path.exists("/tmp/output.zip"):
            os.remove("/tmp/output.zip")
