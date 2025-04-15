import json
import boto3
import time
from uuid import uuid4
from botocore.exceptions import ClientError

# Resources
offers_table = boto3.resource('dynamodb').Table('Offers')
s3 = boto3.client('s3')
BUCKET_NAME = 'real-time-offers-archive'

def lambda_handler(event, context):
    for record in event['Records']:
        try:
            if record['eventName'] != 'INSERT':
                continue

            data = record['dynamodb']['NewImage']

            user_id = data.get('user_id', {}).get('S')
            product_id = data.get('product_id', {}).get('S')
            timestamp = data.get('timestamp', {}).get('S')

            if not all([user_id, product_id, timestamp]):
                print("⚠️ Missing required fields in record:", data)
                continue

            offer = {
                'user_id': user_id,
                'offer_id': str(uuid4()),
                'message': f"Special offer on {product_id} just for you!",
                'timestamp': timestamp
            }

            # Save to Offers Table
            offers_table.put_item(Item=offer)

            # Save to S3
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=f"offers/{user_id}/{int(time.time())}.json",
                Body=json.dumps(offer)
            )

            print(f"✅ Offer created for user {user_id}")

        except ClientError as e:
            print(f"❌ AWS Error: {e.response['Error']['Message']}")
        except Exception as ex:
            print(f"❌ General Error: {str(ex)}")
