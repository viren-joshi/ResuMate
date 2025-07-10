variable "sagemaker_execution_role_arn" {
    type = string
    description = "IAM Role that is allowed to create/execute SageMaker instances."
}

variable "security_group_id" {
    type = string
    description = "Security Group ID for SageMaker"
}

variable "subnet_ids" {
    type = list(string)
    description = "List of subnet IDs"
}

variable "vpc_id" {
    type = string
    description = "ID of the VPC"
}

variable "lambda_security_group" {
    type = string
    description = "Security Group of Lambda Function"
}