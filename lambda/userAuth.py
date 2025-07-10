import json
import boto3
import urllib.request
from jose import jwt
from jose.exceptions import JWTError, ExpiredSignatureError
import os

# Replace with your Cognito User Pool info
USER_POOL_ID = os.environ['USER_POOL_ID']
APP_CLIENT_ID = os.environ['APP_CLIENT_ID']  
REGION = "us-east-1"

apigw_handler = boto3.client('apigatewaymanagementapi', endpoint_url=os.environ['WEBSOCKET_CALLBACK_URL'])

# Get the JWKS keys from Cognito
JWKS_URL = f"https://cognito-idp.{REGION}.amazonaws.com/{USER_POOL_ID}/.well-known/jwks.json"
jwks = json.loads(urllib.request.urlopen(JWKS_URL).read())

def lambda_handler(event, context):
    print("CONNECT EVENT:", event)
    # Extract token from query string
    token = event.get('queryStringParameters', {}).get('Authorization')
    connection_id = event.get('requestContext', {}).get('connectionId')
    if not token:
        # apigw_handler.post_to_connection(
        #     ConnectionId=connection_id, 
        #     Data=json.dumps({
        #         "action": "userAuth",
        #         "statusCode": 401,
        #         "body": json.dumps({"message": "Missing Auth Token"})
        #         })
        # )
        return { "statusCode": 401, "body": "Missing token" }

    try:
        # if token == "74a8d4b8-3021-7057-a7c4-f99eaacfeea7":
        #     return {
        #         "statusCode": 200,
        #         "body": "Connected"
        #     }
        # Decode token header to find correct key
        headers = jwt.get_unverified_header(token)
        kid = headers['kid']
        key = next((k for k in jwks['keys'] if k['kid'] == kid), None)

        if not key:
            raise Exception("Public key not found in JWKS")

        # Decode and verify JWT
        claims = jwt.decode(
            token,
            key,
            algorithms=["RS256"],
            audience=APP_CLIENT_ID,  # Optional
            issuer=f"https://cognito-idp.{REGION}.amazonaws.com/{USER_POOL_ID}"
        )
        
        print(f"Authenticated user: {claims['sub']}")

        # apigw_handler.post_to_connection(
        #     ConnectionId=connection_id,
        #     Data=json.dumps({
        #         "action": "userAuth",
        #         "statusCode": 200,
        #         "body": json.dumps({"message": "Authenticated"})
        #         })
        # )

        return {
            "statusCode": 200,
            "body": "Connected"
        }

    except ExpiredSignatureError:
        return { "statusCode": 401, "body": "Token expired" }
    except JWTError as e:
        print(f"JWT validation error: {str(e)}")
        return { "statusCode": 403, "body": "Unauthorized" }
