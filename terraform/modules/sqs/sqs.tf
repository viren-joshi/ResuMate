resource "aws_sqs_queue" "inference_queue" {
  name                        = "inference-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true  # Enables automatic deduplication using message body hash

  tags = {
    Environment = "production"
    Project = "ResuMate"
  }
}

resource "aws_lambda_event_source_mapping" "sqs_event_mapping" {
  event_source_arn = aws_sqs_queue.inference_queue.arn
  function_name    = var.process_and_respond_lambda
  enabled          = true
  batch_size       = 1  # Adjust as needed (max 10 for FIFO)
}
