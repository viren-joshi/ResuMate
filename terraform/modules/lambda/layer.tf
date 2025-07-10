resource "aws_lambda_layer_version" "pgsql_layer" {
    layer_name = "PostgreSQL Layer"
    s3_bucket = var.init_bucket
    s3_key = "lambda-layer/pgsql_layer.zip"
    compatible_runtimes = [ "python3.11" ]

    description = "Python dependencies for lambda layer."

}