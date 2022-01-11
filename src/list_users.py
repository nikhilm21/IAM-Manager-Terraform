import boto3
import json

def handler(message,context):
    
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    response = table.scan()
    print(response)

    return {
        'statusCode': 200,
        'headers': {},
        'body': json.dumps(response['Items'])
    }