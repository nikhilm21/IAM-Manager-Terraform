import boto3
import os
import json


def handler(message, context):

    activity = message['pathParameters']['UserName']
    activity = str(activity.replace('{','').replace('}',''))
    print(activity)
    try:
        client = boto3.client('iam')
        client.delete_user(UserName = activity)
        Sync_IAM()
        return {
        'statusCode': 200,
        'headers': {},
        'body': json.dumps({'msg': 'User deleted'})
    }
        
    except Exception as e:
        return {
        'statusCode': 200,
        'headers': {},
        'body': json.dumps({'msg': 'User Not Deleted'})
    }


def Sync_IAM():

    '''
    Syncs over IAM users and updates them on delete
    '''

    table_name = 'users'
    # region = os.environ.get('REGION', 'us-east-1')


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