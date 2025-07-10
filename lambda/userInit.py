import boto3
import fitz  # PyMuPDF
import re
import os
import json
import time
import psycopg2

s3 = boto3.client('s3')
cloudwatch = boto3.client('cloudwatch')
runtime = boto3.client('sagemaker-runtime')
secretsmanager = boto3.client('secretsmanager')

apigw_handler = boto3.client(
    'apigatewaymanagementapi',
    endpoint_url=os.environ.get('WEBSOCKET_CALLBACK_URL')
)

SECTION_HEADERS = [
    "Summary", "Experience", "Education", "Certifications",
    "Languages", "Publications", "Top Skills", "Contact"
]

SAGEMAKER_ENDPOINT = os.environ.get('SAGEMAKER_EMBEDDING_MODEL_ENDPOINT')
DB_SECRET = os.environ.get('DB_SECRET')  # ARN or name of the secret

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

def extract_text_from_pdf(local_path):
    print("Extracting Text from PDF")
    doc = fitz.open(local_path)
    text = ""
    for page in doc:
        text += page.get_text()
    doc.close()
    return text

def clean_text(text):
    text = re.sub(r'\n+', '\n', text)
    text = re.sub(r'[ \t]+', ' ', text)
    return text.strip()

def split_into_chunks(text):
    print("Splitting into chunks")
    chunks = {}
    current = None
    for line in text.splitlines():
        line = line.strip()
        if line in SECTION_HEADERS:
            current = line
            chunks[current] = ""
        elif current:
            chunks[current] += line + " "
    return chunks

def get_embeddings_from_sagemaker(text):
    print("Getting embeddings from SageMaker")
    response = runtime.invoke_endpoint(
        EndpointName=SAGEMAKER_ENDPOINT,
        ContentType='application/json',
        Body=json.dumps({"inputs": text})
    )
    result = json.loads(response['Body'].read().decode())
    return result['embedding']  # Adjust based on your model’s actual output schema

def store_vectors_in_rds(vectors, user_id, filename_base):
    print("Storing vectors in RDS")
    creds = get_db_credentials()
    conn = psycopg2.connect(
        host=creds['host'],
        port=creds['port'],
        user=creds['user'],
        password=creds['password'],
        dbname=creds['dbname']
    )
    cur = conn.cursor()
    for section, vector in vectors.items():
        section_id = f"{user_id}_{filename_base}_{section.lower().replace(' ', '_')}"
        cur.execute(
            """
            INSERT INTO resume_vectors (id, user_id, section, embedding)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET embedding = EXCLUDED.embedding;
            """,
            (section_id, user_id, section, vector)
        )
    conn.commit()
    cur.close()
    conn.close()

def lambda_handler(event, context):
    start_time = time.time()
    # Extract S3 bucket and object key
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    # Parse user_id and filename from S3 key
    path_parts = key.split('/')
    user_id = path_parts[1]
    filename = path_parts[2]
    filename_base = os.path.splitext(filename)[0]

    # Download PDF to /tmp
    download_path = f"/tmp/{filename}"
    s3.download_file(bucket, key, download_path)

    # Extract and process
    raw_text = extract_text_from_pdf(download_path)
    chunks = split_into_chunks(raw_text)

    # Generate embeddings
    vectors = {}
    for section, content in chunks.items():
        cleaned = clean_text(content)
        if cleaned:
            embedding = get_embeddings_from_sagemaker(cleaned)
            vectors[section] = embedding

    # Store in RDS
    store_vectors_in_rds(vectors, user_id, filename_base)

    # Send WebSocket update
    response = s3.head_object(Bucket=bucket, Key=key)
    connection_id = response['Metadata'].get('connectionid', None)

    end_time = time.time()
    duration = end_time - start_time

    cloudwatch.put_metric_data(
        Namespace='ResuMate',
        MetricData=[
            {
                'MetricName': 'DocumentVectorizationLatency',
                'Value': duration,
                'Unit': 'Seconds',
                'Dimensions': [{'Name': 'User', 'Value': user_id}]
            }
        ]
    )

    if connection_id:
        try:
            apigw_handler.post_to_connection(
                ConnectionId=connection_id,
                Data=json.dumps({
                    "action": "userInit",
                    "statusCode": 200,
                    "body": json.dumps({"message": "Resume parsed.", "fileName": filename})
                })
            )
        except Exception as e:
            print(f"Error sending message to WebSocket: {e}")

    return {
        "statusCode": 200,
        "body": f"Resume '{filename}' for user '{user_id}' processed and stored in RDS with vector embeddings."
    }
