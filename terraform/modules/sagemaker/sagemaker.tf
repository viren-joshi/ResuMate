
resource "aws_security_group" "sagemaker_sg" {
  name        = "sagemaker-sg"
  description = "Allow traffic only from Lambda SG"
  vpc_id      = var.vpc_id 

  ingress {
    from_port       = 443  
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.lambda_security_group]  # Lambda SG allowed
    description     = "Allow HTTPS traffic from Lambda Security Group"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound to anywhere
  }

  tags = {
    Name = "sagemaker-sg"
  }
}


# SageMaker Model for Embedding
resource "aws_sagemaker_model" "embedding_model" {
  name               = "ResuMate-Embedder"
  execution_role_arn = var.sagemaker_execution_role_arn

  primary_container {
    image               = "763104351884.dkr.ecr.us-east-1.amazonaws.com/huggingface-pytorch-inference:2.1.0-transformers4.37.0-cpu-py310-ubuntu20.04"
    environment = {
      HF_MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"
      HF_TASK     = "feature-extraction"
    }
    mode = "SingleModel"
  }

  vpc_config {
    security_group_ids = [ var.security_group_id ]
    subnets            = var.subnet_ids
  }
}

resource "aws_sagemaker_endpoint_configuration" "embedding_config" {
  name = "ResuMate-Embedder-Configuration"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.embedding_model.name
    initial_instance_count = 1
    instance_type          = "ml.t3.medium"
  }
}

resource "aws_sagemaker_endpoint" "embedding_endpoint" {
  name                 = "ResuMate-Embedder-Endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.embedding_config.name
}

# SageMaker Model for LLM
resource "aws_sagemaker_model" "llm_model" {
  name               = "Resumate-LLM"
  execution_role_arn = var.sagemaker_execution_role_arn

  primary_container {
    image               = "763104351884.dkr.ecr.us-east-1.amazonaws.com/huggingface-pytorch-inference:2.1.0-transformers4.37.0-cpu-py310-ubuntu20.04"
    environment = {
      HF_MODEL_ID = "google/flan-t5-base"
      HF_TASK     = "text2text-generation"
    }
    mode = "SingleModel"
  }

  vpc_config {
    security_group_ids = [ var.security_group_id ]
    subnets            = var.subnet_ids
  }
}

resource "aws_sagemaker_endpoint_configuration" "llm_config" {
  name = "Resumate-LLM-Configuration"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.llm_model.name
    initial_instance_count = 1
    instance_type          = "ml.m5.xlarge"
  }
}



resource "aws_sagemaker_endpoint" "llm_endpoint" {
  name                 = "Resumate-LLM-Endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.llm_config.name
}

output "sagemaker_embedder_model_arn" {
    value = aws_sagemaker_endpoint.embedding_endpoint.arn
}

output "sagemaker_llm_model_arn" {
    value = aws_sagemaker_endpoint.llm_endpoint.arn
}