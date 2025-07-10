import json
import boto3
import os

apigw_handler = boto3.client('apigatewaymanagementapi', endpoint_url=os.environ['WEBSOCKET_CALLBACK_URL'])

s3 = boto3.client('s3')
bucket = os.environ['S3_BUCKET_NAME']

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    user_id = json.loads(event.get('body', '{}')).get('userId', '')

    try:
         # Look through /userData/{user_id} and get all the files
        response = s3.list_objects_v2(Bucket=bucket, Prefix=f'userData/{user_id}/')
        print(response)
        if 'Contents' in response:
            object_keys = [obj['Key'].split('/')[-1] for obj in response['Contents']]
            
            apigw_handler.post_to_connection(
                ConnectionId=connection_id, 
                Data=json.dumps({
                    'action': 'fetchUserData',
                    'statusCode': 200,
                    'files': object_keys})
            )

            return {
                'statusCode': 200,
                'body': json.dumps({'files': object_keys})
            }
            
        else:
            apigw_handler.post_to_connection(
                ConnectionId=connection_id, 
                Data=json.dumps({
                    'action': 'fetchUserData',
                    'statusCode': 200,
                    'files': [],
                    'message': "No files found for the user."
                })
            )
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'No files found for the user.'})
            }
    except Exception as e:
        apigw_handler.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps({
                'action': 'fetchUserData',
                'statusCode': 500,
                'error': str(e)})
        )
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
