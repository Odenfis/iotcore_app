import json
import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('wmr_iot_data')

def lambda_handler(event, context):
    try:
        # Get device_id from query parameters
        query_params = event.get('queryStringParameters', {})
        device_id = query_params.get('device_id')
        
        if device_id:
            # Query items for a specific device, sorted by timestamp descending
            response = table.query(
                KeyConditionExpression=Key('device_id').eq(device_id),
                ScanIndexForward=False, # Descending order
                Limit=20
            )
            items = response.get('Items', [])
        else:
            # Scan the table (limited to 20 items)
            response = table.scan(Limit=20)
            items = response.get('Items', [])
        
        # The data in the screenshot shows payload as a map containing the values
        # We want to flatten it for the frontend
        flattened_items = []
        for item in items:
            payload = item.get('payload', {})
            flattened_items.append({
                'device_id': item.get('device_id'),
                'timestamp': item.get('timestamp'),
                'temperature': payload.get('temperature', 'N/A'),
                'humidity': payload.get('humidity', 'N/A')
            })
            
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*' # Enable CORS for Flutter Web/Mobile
            },
            'body': json.dumps(flattened_items)
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }
