from sagemaker.huggingface import HuggingFaceModel
from sagemaker import get_execution_role, Session

role = get_execution_role()
session = Session()

# 1️⃣ Embedding Model - Sentence Transformers
embedding_model = HuggingFaceModel(
    role=role,
    transformers_version="4.37.0",
    pytorch_version="2.1.0",
    py_version="py310",
    env={
        "HF_MODEL_ID": "sentence-transformers/all-MiniLM-L6-v2",
        "HF_TASK": "feature-extraction"
    },
    vpc_config={
        'Subnets': ['subnet-0a45d28802e8d30ba', 'subnet-09e77890a0cbbba5a'],
        'SecurityGroupIds': ['sg-025175313c4f6da31']
    }
)

embedding_predictor = embedding_model.deploy(
    initial_instance_count=1,
    instance_type="ml.t3.medium",  # Low-cost instance for embeddings
    endpoint_name="mini-lm-embedding-endpoint"
)

# 2️⃣ LLM Model - Flan-T5 Base
llm_model = HuggingFaceModel(
    role=role,
    transformers_version="4.37.0",
    pytorch_version="2.1.0",
    py_version="py310",
    env={
        "HF_MODEL_ID": "google/flan-t5-base",
        "HF_TASK": "text2text-generation"
    },
    vpc_config={
        'Subnets': ['subnet-0a45d28802e8d30ba', 'subnet-09e77890a0cbbba5a'],
        'SecurityGroupIds': ['sg-025175313c4f6da31']
    }
)

llm_predictor = llm_model.deploy(
    initial_instance_count=1,
    instance_type="ml.m5.xlarge",  # Balanced for LLM inference
    endpoint_name="flan-t5-base-endpoint"
)

# Example Predictions:
embedding_response = embedding_predictor.predict({
    "inputs": "Generate text embeddings for this sentence."
})
print("Embedding Output:", embedding_response)

llm_response = llm_predictor.predict({
    "inputs": "Write a cover letter for a data science role at Microsoft."
})
print("LLM Output:", llm_response)
