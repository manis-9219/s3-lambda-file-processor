import boto3
from PIL import Image
from io import BytesIO
import os

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Get bucket and object key from the event
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    destination_bucket = source_bucket  # same bucket (or use a different one)
    filename = os.path.basename(key)  # strips off folder structure
    resized_key = f"resized/{filename}"

    # Download image from S3
    image_obj = s3.get_object(Bucket=source_bucket, Key=key)
    image_content = image_obj['Body'].read()

    # Open and resize
    image = Image.open(BytesIO(image_content))
    image = image.resize((300, 300))  # Resize to 300x300

    # 🔧 Ensure compatibility with JPEG format
    if image.mode in ("RGBA", "P"):
        image = image.convert("RGB")

    # Save to buffer
    buffer = BytesIO()
    image_format = image.format if image.format in ["JPEG", "PNG"] else "JPEG"  # 🔧 safer fallback
    content_type = "image/jpeg" if image_format == "JPEG" else "image/png"      # 🔧 set correct MIME type

    image.save(buffer, format=image_format)
    buffer.seek(0)

    # Upload resized image
    s3.put_object(
        Bucket=destination_bucket,
        Key=resized_key,
        Body=buffer,
        ContentType=content_type  # 🔧 use correct content type
    )

    return {
        'statusCode': 200,
        'body': f'Resized image saved to {resized_key}'
    }
