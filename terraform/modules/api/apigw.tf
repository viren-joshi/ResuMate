resource "aws_apigatewayv2_api" "websocket_api" {
  name          = "resumate-websocket-api"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# Integrations
resource "aws_apigatewayv2_integration" "userAuth_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.userAuth_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "userInference_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.userInference_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "fetchUserData_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.fetchUserData_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "userDocUpload_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.userDocUpload_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Routes
resource "aws_apigatewayv2_route" "connect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
  authorization_type = "NONE"
  target = "integrations/${aws_apigatewayv2_integration.userAuth_integration.id}"
}

resource "aws_apigatewayv2_route" "disconnect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$disconnect"
  authorization_type = "NONE"
  target = "integrations/${aws_apigatewayv2_integration.userAuth_integration.id}" # Adjust to real mock/empty Lambda if needed
}

resource "aws_apigatewayv2_route" "createCoverLetter_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "createCoverLetter"
  target    = "integrations/${aws_apigatewayv2_integration.userInference_integration.id}"
}

resource "aws_apigatewayv2_route" "fetchUserData_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "fetchUserData"
  target    = "integrations/${aws_apigatewayv2_integration.fetchUserData_integration.id}"
}

resource "aws_apigatewayv2_route" "uploadResume_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "uploadResume"
  target    = "integrations/${aws_apigatewayv2_integration.userDocUpload_integration.id}"
}

# Deployment
resource "aws_apigatewayv2_deployment" "websocket_deployment" {
  api_id = aws_apigatewayv2_api.websocket_api.id

  depends_on = [
    aws_apigatewayv2_route.connect_route,
    aws_apigatewayv2_route.disconnect_route,
    aws_apigatewayv2_route.createCoverLetter_route,
    aws_apigatewayv2_route.fetchUserData_route,
    aws_apigatewayv2_route.uploadResume_route
  ]
}

resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id      = aws_apigatewayv2_api.websocket_api.id
  name        = "prod"
  deployment_id = aws_apigatewayv2_deployment.websocket_deployment.id
  auto_deploy = true
}
