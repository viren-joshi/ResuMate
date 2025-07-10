resource "aws_lambda_function" "verify_user" {
    function_name = "verifyUser"
    role = var.lab_role_arn
    handler = "python3.11"
    timeout = 30

    s3_bucket = var.init_bucket
    s3_key = "lambda-code/verify_user.zip"

    tags = {
      Project = "ResuMate"
    }
}