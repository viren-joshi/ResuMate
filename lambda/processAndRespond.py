import json
import boto3
import os
import time

sqs = boto3.client('sqs')
apigw_handler = boto3.client('apigatewaymanagementapi', endpoint_url=os.environ['WEBSOCKET_CALLBACK_URL'])
sm_runtime = boto3.client('sagemaker-runtime')

cloudwatch = boto3.client('cloudwatch')

# ENV variables (set in Lambda console)
SAGEMAKER_ENDPOINT_NAME = os.environ['SAGEMAKER_LLM_ENDPOINT'] 

MAX_TOKENS_THRESHOLD = 300  # adjust as needed

def expand_prompt(previous_prompt, previous_output):
    return (
        previous_prompt.strip() +
        "\n\nPrevious Draft:\n" + previous_output.strip() +
        "\n\nPlease improve and expand upon the previous draft based on the resume and job description above."
    )

def call_sagemaker_endpoint(prompt):
    payload = {
        "inputs": prompt,
        "parameters": {
            "temperature": 0.7,
            "max_new_tokens": 200,
            "top_k": 50,
            "top_p": 0.95,
            "do_sample": True,
            "repetition_penalty": 1.1,
        }
    }

    response = sm_runtime.invoke_endpoint(
        EndpointName=SAGEMAKER_ENDPOINT_NAME,
        ContentType="application/json",
        Body=json.dumps(payload)
    )

    result = json.loads(response["Body"].read().decode("utf-8"))
    return result[0]["generated_text"]

def lambda_handler(event, context):
    # Poll message
    for record in event["Records"]:
        print(record)
        body = json.loads(record["body"])
        print(body)
        rag_prompt = body.get("rag_prompt")
        connection_id = body.get("connection_id")
        user_id = body.get("user_id")

        sent_timestamp_ms = int(record["attributes"]["SentTimestamp"])
        now_ms = int(time.time() * 1000)
        latency_ms = now_ms - sent_timestamp_ms

        cloudwatch.put_metric_data(
            Namespace='ResuMate',
            MetricData=[
                {
                    'MetricName': 'SQSLatency',
                    'Value': latency_ms,
                    'Unit': 'Milliseconds',
                    'Timestamp': sent_timestamp_ms / 1000,
                }
            ]
        )

        try:
            if not rag_prompt or not connection_id:
                print("Missing required fields")
                continue

            full_output = ""
            prompt = rag_prompt

            for _ in range(3):  # Allow up to 3 expansion cycles
                output = call_sagemaker_endpoint(prompt)
                full_output += output.strip() + "\n"

                apigw_handler.post_to_connection(
                    ConnectionId=connection_id,
                    Data=json.dumps({
                        "action": "processAndRespond",
                        "user_id": user_id,
                        "message": full_output.strip()
                    }).encode("utf-8")
                )

                if len(full_output.split()) >= MAX_TOKENS_THRESHOLD:
                    break
                # Expand prompt with the generated output
                prompt = expand_prompt(rag_prompt, full_output.strip())

            print(full_output)
            
        except Exception as e:
            print(f"WebSocket send error: {str(e)}")
            try:
                apigw_handler.post_to_connection(
                    ConnectionId=connection_id,
                    Data=json.dumps({
                        "action": "processAndRespond",
                        "user_id": user_id,
                        "message": full_output.strip()
                    }).encode("utf-8")
                )
            except Exception as e:
                print(f"Error sending message to WebSocket: {str(e)}")

    return {"status": "success"}
