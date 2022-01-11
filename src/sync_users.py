import boto3
import os
import json
import uuid
from datetime import datetime


def handler(message, context):

    Sync_IAM()

    return {
        'statusCode': 201,
        'headers': {},
        'body': json.dumps({'msg': 'Sync Complete'})
    }


def Sync_IAM():

    '''
    Syncs over IAM users and updates them on delete
    '''

    table_name = 'users'


    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(table_name)

    scan = table.scan()
    with table.batch_writer() as batch:
        for each in scan['Items']:
            batch.delete_item(
                Key={
                    'UserName': each['UserName']
                }
            )

    client = boto3.client('iam')
    response = client.list_users()

    for i in response['Users']:
        i.pop('CreateDate')  
        table.put_item(Item=i)

    print('DB Sync Completed')