# ResuMate

ResuMate is a cloud-based AI-powered web application that assists job seekers in creating personalized cover letters tailored to specific job descriptions. It streamlines the application process by combining user resume data with job postings to generate highly relevant, professional cover letters.


## Project Overview
ResuMate leverages **Retrieval-Augmented Generation (RAG)** to provide tailored cover letters based on a user's uploaded resume and a specific job description.

Key highlights:
- Uses **pgvector** with PostgreSQL for vector similarity search.
- Embedding models and Large Language Models (LLMs) are self-hosted on **Amazon SageMaker** for both vectorization and text generation.
- Entire solution is built on AWS, ensuring scalability, security, and efficiency.
- Initially focused on cover letter generation, with plans to expand to resume generation in future versions.


## Key Features

- Personalized Cover Letter Generation  
- User Authentication & Authorization via Amazon Cognito
- Secure Resume Uploads using Pre-signed S3 URLs
- Semantic Search with PostgreSQL + pgvector
- RAG Pipeline for Context-Aware Generation
- LLM Text Generation on Amazon SageMaker
- WebSocket-based Real-time Communication
- CloudWatch-based Monitoring and Logging


## Architecture Overview

> ![ResuMate_Simplified_Architecture](https://github.com/user-attachments/assets/c18c41bd-4241-4f44-be5b-8a2438a346ac)
> ResuMate Architecture Overview


**Workflow Summary:**

1. **User Initialization**:
   - Users upload resumes via secure pre-signed S3 URLs.
   - Resume is parsed, vectorized via embedding model on SageMaker, and stored in PostgreSQL with pgvector for future similarity queries.

2. **Job Inference**:
   - User submits job description.
   - Text is vectorized and used to query PostgreSQL to retrieve similar resume sections.
   - System creates a prompt combining resume data with job description.
   - Prompt is queued in SQS for LLM generation.

3. **LLM Processing & Result Delivery**:
   - Lambda retrieves prompt from SQS, queries LLM hosted on SageMaker.
   - Performs iterative prompting if necessary for enhanced generation.
   - Generated cover letter is returned via WebSocket API to frontend.


**Security Measures:**
- Private subnets for Lambda and SageMaker endpoints inside VPC.
- S3 uploads secured with pre-signed URLs, hidden from user interface.
- JWT tokens verified before API access via Amazon Cognito.


## Core AWS Services Used

| Service               | Purpose                                                 |
|-----------------------|---------------------------------------------------------|
| Amazon S3             | Static website hosting & secure document storage        |
| Amazon Cognito        | User authentication, authorization, JWT-based sessions  |
| AWS Lambda            | Backend logic (vectorization, RAG, orchestration)       |
| Amazon API Gateway    | WebSocket APIs for real-time communication              |
| Amazon SQS            | Decoupled prompt queue for LLM processing               |
| Amazon SageMaker      | Embedding & LLM Model Hosting (Inference)               |
| Amazon RDS (PostgreSQL + pgvector) | Vector database for semantic search       |
| Amazon CloudWatch     | Logging, monitoring, custom metrics, and alarms         |
| Amazon SNS            | Notifications for critical alarms                       |


## Lambda Functions Overview

| Lambda Function    | Description                                                                                           |
|--------------------|-------------------------------------------------------------------------------------------------------|
| `userInit`         | Parses uploaded resume, vectorizes using embedding model, stores vectors in PostgreSQL + pgvector.     |
| `userInference`    | Accepts job description, performs vector search, constructs RAG prompt, and queues for LLM processing. |
| `processAndRespond`| Invoked by SQS; uses LLM for cover letter generation and supports iterative prompting for improved results. |
| `userDocUpload`    | Generates secure pre-signed S3 URL for resume uploads.                                                 |
| `fetchUserData`    | Lists uploaded resume filenames for the authenticated user from S3 bucket.                            |
| `userAuth`         | Authorizes WebSocket connections by validating JWT tokens with Cognito.                               |
| `userDisconnect`   | Dummy Lambda invoked on WebSocket disconnect events.                                                   |
| `verifyUser`       | Verifies users in Cognito (used if email verification flow is added later).                           |

## Detailed Architecture

>![image](https://github.com/user-attachments/assets/99317d96-3d4c-4152-a664-a3fc27e8856c)
> Detailed ResuMate Architecture


## Future Improvements

- Integrate Chat-based LLM interactions for more customized application materials.
- Explore fine-tuned or quantized LLM models for better quality & lower costs.
- Further enhance embedding models for better vectorization performance.
- Add full user dashboard with history of generated documents.

