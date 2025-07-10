resource "aws_lambda_function" "process_and_respond" {
    function_name = "processAndRespond"
    role = var.lab_role_arn
    handler = "processAndRespond.lambda_handler"
    runtime = "python3.11"
    timeout = 30

    s3_bucket = var.init_bucket
    s3_key = "lambda-code/process_and_respond.zip"

    vpc_config {
      subnet_ids = var.subnet_ids
      security_group_ids = [ var.security_group_id ]
    }

    tags = {
      Project = "ResuMate"
    }

    environment {
      variables = {
        WEBSOCKET_CALLBACK_URL = var.websocket_callback_url
        SAGEMAKER_LLM_ENDPOINT = var.sagemaker_llm_model_endpoint
      }
    }
}