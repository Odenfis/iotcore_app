import json
from decimal import Decimal

import boto3
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('wmr_iot_data')

# Número máximo de lecturas devueltas al frontend.
MAX_ITEMS = 20


class DecimalEncoder(json.JSONEncoder):
    """Convierte los Decimal de DynamoDB en tipos serializables por JSON."""

    def default(self, obj):
        if isinstance(obj, Decimal):
            # Los enteros se devuelven como int para no romper el contrato
            # (el frontend espera un epoch en segundos) y los decimales como
            # float.
            if obj % 1 == 0:
                return int(obj)
            return float(obj)
        return super().default(obj)


def _flatten(item):
    """Normaliza un item de DynamoDB al formato que consume la app Flutter."""
    payload = item.get('payload', {}) or {}
    return {
        'device_id': item.get('device_id'),
        'timestamp': item.get('timestamp'),
        'temperature': payload.get('temperature', 'N/A'),
        'humidity': payload.get('humidity', 'N/A'),
    }


def _scan_all():
    """Recorre la tabla completa paginando (Scan no guarantee orden)."""
    items = []
    scan_kwargs = {}
    while True:
        response = table.scan(**scan_kwargs)
        items.extend(response.get('Items', []))
        last_key = response.get('LastEvaluatedKey')
        if not last_key:
            break
        scan_kwargs['ExclusiveStartKey'] = last_key
    return items


def lambda_handler(event, context):
    try:
        query_params = event.get('queryStringParameters') or {}
        device_id = query_params.get('device_id')

        if device_id:
            # Query para un dispositivo concreto, ya ordenado de más reciente a
            # más antiguo.
            response = table.query(
                KeyConditionExpression=Key('device_id').eq(device_id),
                ScanIndexForward=False,  # Descending order
                Limit=MAX_ITEMS
            )
            items = response.get('Items', [])
        else:
            # Sin filtro devolvemos las MAX_ITEMS lecturas más recientes de
            # toda la tabla: el Scan por sí solo no garantiza el orden.
            items = _scan_all()
            items.sort(key=lambda item: item.get('timestamp', 0), reverse=True)
            items = items[:MAX_ITEMS]

        # Aplanamos el payload anidado para el frontend.
        flattened_items = [_flatten(item) for item in items]

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'  # Enable CORS for Flutter Web/Mobile
            },
            'body': json.dumps(flattened_items, cls=DecimalEncoder)
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
