resource "aws_lambda_function" "user_init" {
    function_name = "userInit"
    role = var.lab_role_arn
    handler = "userInit.lambda_handler"
    runtime = "python3.11"
    timeout = 30

    s3_bucket = var.init_bucket
    s3_key = "lambda-code/user_init.zip"

    vpc_config {
      subnet_ids = var.subnet_ids
      security_group_ids = [ var.security_group_id ]
    }

    tags = {
      Project = "ResuMate"
    }

    layers = [ aws_lambda_layer_version.pgsql_layer.arn ]

    environment {
      variables = {
        SQS_ENDPOINT = var.sqs_endpoint
        WEBSOCKET_CALLBACK_URL = var.websocket_callback_url
        SAGEMAKER_EMBEDDING_MODEL_ENDPOINT = var.sagemaker_embedding_model_endpoint
        DB_SECRET = var.db_secret
      }
    }
}