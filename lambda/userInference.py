import json
import boto3
import os
import psycopg2

# SQS init
sqs = boto3.client('sqs')
SQS_QUEUE_URL = os.environ.get('SQS_ENDPOINT')

apigw_management = boto3.client(
    'apigatewaymanagementapi',
    endpoint_url=os.environ.get('WEBSOCKET_CALLBACK_URL'),
    region_name='us-east-1'
)

cloudwatch = boto3.client('cloudwatch')
secretsmanager = boto3.client('secretsmanager')

SAGEMAKER_ENDPOINT = os.environ.get('SAGEMAKER_EMBEDDING_MODEL_ENDPOINT')
DB_SECRET = os.environ.get('DB_SECRET') 

def get_db_credentials():
    """Fetch DB credentials from AWS Secrets Manager."""
    response = secretsmanager.get_secret_value(SecretId=DB_SECRET)
    secret = json.loads(response['SecretString'])
    return {
        'host': secret['host'],
        'port': secret.get('port', 5432),
        'user': secret['username'],
        'password': secret['password'],
        'dbname': secret['dbname']
    }

def query_similar_sections(user_id, job_embedding, top_k=10):
    """Query RDS PostgreSQL (pgvector) for similar vectors to job embedding."""
    print("Querying RDS for similar sections")
    creds = get_db_credentials()
    conn = psycopg2.connect(
        host=creds['host'],
        port=creds['port'],
        user=creds['user'],
        password=creds['password'],
        dbname=creds['dbname']
    )
    cur = conn.cursor()
    query = """
        SELECT section, text
        FROM resume_vectors
        WHERE user_id = %s
        ORDER BY embedding <-> %s
        LIMIT %s;
    """
    cur.execute(query, (user_id, job_embedding, top_k))
    results = cur.fetchall()
    cur.close()
    conn.close()
    return results  # list of (section, text)

def lambda_handler(event, context):
    try:
        # Parse input from WebSocket message
        body = json.loads(event.get('body', '{}'))
        text = body['text']
        user_id = body['userId']
        connection_id = event['requestContext']['connectionId']

        if not text.strip():
            apigw_management.post_to_connection(
                ConnectionId=connection_id,
                Data=json.dumps({
                    "action": "userInference",
                    'statusCode': 400,
                    'body': json.dumps({'message': 'Please enter a job description'})
                })
            )
            print("Please enter a job description")
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Please enter a job description', "action": "userInference"})
            }

        # Get embedding for the job description from SageMaker
        runtime = boto3.client('sagemaker-runtime')
        response = runtime.invoke_endpoint(
            EndpointName=SAGEMAKER_ENDPOINT,
            ContentType='application/json',
            Body=json.dumps({"inputs": text})
        )
        job_embedding = json.loads(response['Body'].read().decode())['embedding']

        # Query similar resume sections from RDS using pgvector
        results = query_similar_sections(user_id, job_embedding)

        # Combine search result data (RAG-style)
        relevant_contexts = [text for section, text in results]
        print(relevant_contexts)
        context_block = "\n".join(relevant_contexts)

        # Prompt Engineering
        rag_prompt = f"""
            You are an expert career assistant. Use the following resume content and job description to generate a tailored cover letter for the user.
            Resume:
            {context_block}

            Job Description:
            {text}

            Instructions:
            - Highlight the user's most relevant experiences for the job.
            - Match skills and achievements from the resume to the job requirements.
            - Generate a tailored cover letter.
            - Keep it concise and professional.
            """

        # Send to SQS for SageMaker
        sqs.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps({
                "rag_prompt": rag_prompt,
                "user_id": user_id,
                "connection_id": connection_id
            }),
            MessageGroupId='resuMate'
        )
        apigw_management.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps({
                "action": "userInference",
                'statusCode': 200,
                'body': json.dumps({'message': 'Prompt sent to SageMaker queue successfully'})
            })
        )
        print("Prompt sent to SageMaker queue successfully")
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Prompt sent to SageMaker queue successfully', "action": "userInference"})
        }

    except Exception as e:
        print("Error:", e)
        apigw_management.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps({
                "action": "userInference",
                'statusCode': 500,
                'body': json.dumps({'error': str(e)})
            })
        )
        return {
            'statusCode': 500,
            'body': json.dumps({'message': str(e), "action": "userInference"})
        }
