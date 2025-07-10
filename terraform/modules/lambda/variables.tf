variable "lab_role_arn" {
    type = string
    description = "Lab Role ARN"
    default = ""
}

variable "subnet_ids" {
    type = list(string)
    description = "List of subnet IDs"
}

variable "security_group_id" {
    type = string
    description = "Security Group ID"
}

variable "user_document_bucket" {
    type = string
    description = "User Document Bucket name."
}

variable "websocket_callback_url" {
    type = string
    description = "The endpoint to the API-GW WebSocket"
}

variable "init_bucket" {
    type = string
    description = "The init bucket name"
}

variable "sqs_endpoint" {
    type = string
    description = "Endpoint of SQS"
}

variable "sagemaker_llm_model_endpoint" {
    type = string
    description = "SageMaker LLM Model Endpoint"
}

variable "sagemaker_embedding_model_endpoint" {
    type = string
    description = "SageMaker Embedding Model Endpoint"
}

variable "user_pool_id" {
    type = string
    description = "User Pool ID"
}

variable "app_client_id" {
    type = string
    description = "App Client ID"
}

variable "db_secret" {
    type = string
    description = "AWS SecretManager DB Secret Name"
}