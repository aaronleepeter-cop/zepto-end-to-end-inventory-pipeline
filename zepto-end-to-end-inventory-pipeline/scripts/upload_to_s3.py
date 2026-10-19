"""
Script: upload_to_s3.py
Description: Validates the local Zepto catalog CSV and uploads it to the AWS S3 landing zone.
Author: Aaron Lee Peter
"""

import os
import sys
import logging
import boto3
from botocore.exceptions import NoCredentialsError, ClientError
from dotenv import load_dotenv

# Load environment variables from a local .env file (never committed to Git)
load_dotenv()

# Configure clean console logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

# AWS S3 Configuration
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_REGION = os.getenv("AWS_REGION", "ap-southeast-2")
S3_BUCKET_NAME = os.getenv(
    "S3_BUCKET_NAME", 
    "zepto-inventory-analytics-end-699073937703-ap-southeast-2-an"
)

# File Paths
LOCAL_FILE_PATH = os.path.join("data", "zepto_inventory_sample.csv")
S3_OBJECT_KEY = "raw/zepto_inventory_processed.csv"


def upload_catalog_to_s3(local_path: str, bucket: str, s3_key: str) -> bool:
    """Uploads the processed inventory CSV to the target AWS S3 bucket."""
    if not os.path.exists(local_path):
        logging.error(f"Local file not found at path: {local_path}")
        return False

    try:
        logging.info("Initializing AWS S3 client...")
        s3_client = boto3.client(
            "s3",
            aws_access_key_id=AWS_ACCESS_KEY,
            aws_secret_access_key=AWS_SECRET_KEY,
            region_name=AWS_REGION
        )

        logging.info(f"Uploading '{local_path}' to 's3://{bucket}/{s3_key}'...")
        s3_client.upload_file(local_path, bucket, s3_key)
        logging.info("Upload completed successfully.")
        return True

    except NoCredentialsError:
        logging.error("AWS credentials missing. Check your local .env configuration.")
        return False
    except ClientError as e:
        logging.error(f"AWS ClientError during S3 upload: {e}")
        return False
    except Exception as e:
        logging.error(f"Unexpected error: {e}")
        return False


if __name__ == "__main__":
    success = upload_catalog_to_s3(LOCAL_FILE_PATH, S3_BUCKET_NAME, S3_OBJECT_KEY)
    if not success:
        sys.exit(1)