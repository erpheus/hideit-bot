import boto3
import logging


class Database:

    def __init__(self):
        self.client = boto3.resource(
            'dynamo', aws_access_key_id='0', aws_secret_access_key='0', region_name='eu-central-1', endpoint_url="http://dynamo:8000")

    def read_index(id):
        client = boto3.resource('dynamodb', aws_access_key_id='0',
                              aws_secret_access_key='0', region_name='eu-central-1', endpoint_url="http://dynamo:8000")
        # implement reading index
        messages = client.Table('messages')
        response = messages.get_item(
            Key={
                'id': id
            }
        )

        return response.get('Item').get('msg')

    def store_index(id, msg):
        client = boto3.resource('dynamodb', aws_access_key_id='0',
                              aws_secret_access_key='0', region_name='eu-central-1', endpoint_url="http://dynamo:8000")
        # implement storing index
        messages = client.Table('messages')
        messages.put_item(
                Item={
                    'id': id,
                    'msg': msg
                }
        )
