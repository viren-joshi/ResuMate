resource "aws_lambda_function" "user_auth" {
    function_name = "userAuth"
    role = var.lab_role_arn
    handler = "userAuth.lambda_handler"
    runtime = "python3.11"
    timeout = 30

    s3_bucket = var.init_bucket
    s3_key = "lambda-code/user_auth.zip"

    vpc_config {
      subnet_ids = var.subnet_ids
      security_group_ids = [ var.security_group_id ]
    }

    tags = {
      Project = "ResuMate"
    }

    environment {
      variables = {
        USER_POOL_ID = var.user_pool_id
        APP_CLIENT_ID = var.app_client_id
        WEBSOCKET_CALLBACK_URL = var.websocket_callback_url
      }
    }
}