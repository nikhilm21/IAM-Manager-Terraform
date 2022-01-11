import boto3
import os
import json
from boto3.dynamodb.conditions import Key


def handler(message, context):

    activities_table = boto3.resource('dynamodb',region_name="us-east-2")

    table = activities_table.Table('users')
    activity_id = message['pathParameters']['UserName']
    activity_id = str(activity_id.replace('{','').replace('}',''))
    print(activity_id)

    
    try:
        response = table.get_item(
            Key = {
                'UserName': activity_id
            }
        )

        return {
        'statusCode': 400,
        'headers': {},
        'body': json.dumps(response['Item'])
        }

    except:
        return {
        'statusCode': 400,
        'headers': {},
        'body': json.dumps({'msg': 'User Not Found'})
        }