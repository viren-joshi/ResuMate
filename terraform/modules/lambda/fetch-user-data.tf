resource "aws_lambda_function" "fetch_user_data" {
    function_name = "fetchUserData"
    role = var.lab_role_arn
    handler = "fetchUserData.lambda_handler"
    runtime = "python3.11"
    timeout = 30

    s3_bucket = var.init_bucket
    s3_key = "lambda-code/fetch_user_data.zip"

    vpc_config {
      subnet_ids = var.subnet_ids
      security_group_ids = [ var.security_group_id ]
    }

    tags = {
      Project = "ResuMate"
    }

    environment {
      variables = {
        S3_BUCKET_NAME = var.user_document_bucket
        WEBSOCKET_CALLBACK_URL = var.websocket_callback_url
      }
    }
}