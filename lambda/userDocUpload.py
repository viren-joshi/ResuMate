import json
import boto3
import os

s3_client = boto3.client('s3')
apigw_client = boto3.client('apigatewaymanagementapi', endpoint_url=os.environ['WEBSOCKET_CALLBACK_URL'])

BUCKET_NAME = os.environ.get("S3_BUCKET_NAME", "")

def lambda_handler(event, context):
    print(event)
    body = json.loads(event.get('body', '{}'))

    user_id = body.get('userId')
    file_name = body.get('fileName')

    connection_id = event.get('requestContext', {}).get('connectionId')
    try:
        if not user_id or not file_name:
            print("Missing required parameters")

            apigw_client.post_to_connection(
                ConnectionId=connection_id,
                Data=json.dumps({
                    'action': 'userDocUpload',
                    'statusCode': 400,
                    'message': 'Missing required parameters'
                })
            )


            return {"statusCode": 400, "body" : json.dumps({"message": "Missing required parameters"})}

        object_key = f"userData/{user_id}/{file_name}"

        presigned_url = s3_client.generate_presigned_url(
            ClientMethod='put_object',
            Params={
                'Bucket': BUCKET_NAME,
                'Key': object_key,
                'ContentType': 'application/pdf',
                'Metadata': {
                    'connectionId': connection_id
                }
            },
            ExpiresIn=300  # URL valid for 5 minutes
        )

        print(presigned_url)

        apigw_client.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps({
                'action': 'userDocUpload',
                'statusCode': 200,
                'url': presigned_url,
                'objectKey': object_key
            })
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "url": presigned_url,
                "objectKey": object_key
            })
        }

    except Exception as e:

        apigw_client.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps({
                'action': 'userDocUpload',
                'statusCode': 500,
                'message': str(e)
            })
        )

        return {
            "statusCode": 500,
            "message": f"Error generating pre-signed URL: {str(e)}"
        }