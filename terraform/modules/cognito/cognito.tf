resource "aws_cognito_user_pool" "resumate_user_pool" {
    name = "ResuMateUserPool"

    username_attributes = ["email"]
    auto_verified_attributes = ["email"]

    lambda_config {
      post_authentication = var.verify_user_lambda
    }

    password_policy {
        minimum_length = 8
        require_uppercase = true
        require_lowercase = true
        require_numbers   = true
        require_symbols   = false
    }

    account_recovery_setting {
        recovery_mechanism {
          name = "verified_email"
          priority = 1
        }
    }
}

resource "aws_cognito_user_pool_client" "web_client" {
    name = "ResuMate Web Client"
    user_pool_id = aws_cognito_user_pool.resumate_user_pool.id
    generate_secret = false

    explicit_auth_flows = [
        "ALLOW_USER_PASSWORD_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH",
        "ALLOW_USER_SRP_AUTH"
    ]
}

output "user_pool_id" {
    value = aws_cognito_user_pool.resumate_user_pool.id
}

output "web_client_id" {
    value = aws_cognito_user_pool_client.web_client.id
}
