import json
import base64
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('BrowsingEvents')

def lambda_handler(event, context):
    for record in event['Records']:
        payload = base64.b64decode(record['kinesis']['data'])
        data = json.loads(payload, parse_float=Decimal)
        table.put_item(Item=data)
