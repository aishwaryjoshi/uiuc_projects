import boto3
import json
import time
import random
from datetime import datetime

# Configuration
STREAM_NAME = 'BrowsingClickstream'
REGION = 'us-east-1'  # Change based on your AWS setup

# Sample data
users = ['USR101', 'USR102', 'USR103', 'USR104', 'USR105', 'USR106', 'USR107', 'USR108', 'USR109', 'USR110']
products = [
    {'id': 'PRD001', 'category': 'books'},
    {'id': 'PRD002', 'category': 'electronics'},
    {'id': 'PRD003', 'category': 'fashion'},
    {'id': 'PRD004', 'category': 'home'},
    {'id': 'PRD005', 'category': 'sports'}
]

# Boto3 client
kinesis = boto3.client('kinesis', region_name=REGION)

def generate_event():
    user = random.choice(users)
    product = random.choice(products)
    event = {
        'user_id': user,
        'session_id': f'SES{random.randint(1000, 9999)}',
        'product_id': product['id'],
        'category': product['category'],
        'action': 'view',
        'timestamp': datetime.utcnow().isoformat()
    }
    return event

def send_event(event):
    response = kinesis.put_record(
        StreamName=STREAM_NAME,
        Data=json.dumps(event),
        PartitionKey=event['user_id']
    )
    print(f"Sent: {event}")

if __name__ == '__main__':
    for _ in range(500):  # Send 500 events
        evt = generate_event()
        send_event(evt)
        time.sleep(random.uniform(0.5, 1.5))  # Simulate realistic browsing delay
