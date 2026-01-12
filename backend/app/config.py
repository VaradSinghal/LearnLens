"""Application configuration."""
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """Application settings."""
    
    # Server
    ENVIRONMENT: str = "development"
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000
    API_PREFIX: str = "/api/v1"
    
    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = "./firebase-credentials.json"
    FIREBASE_PROJECT_ID: str = ""
    
    # Pinecone Vector DB
    PINECONE_API_KEY: str = ""
    PINECONE_ENVIRONMENT: str = "us-east-1"  # Default region
    PINECONE_INDEX_NAME: str = "learnlens"
    
    # LLM Providers
    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""
    GOOGLE_API_KEY: str = ""
    LLM_PROVIDER: str = "openai"  # openai, anthropic, google
    LLM_MODEL: str = "gpt-4-turbo-preview"
    
    # Embeddings (required for Pinecone)
    EMBEDDING_PROVIDER: str = "openai"  # Required for Pinecone
    EMBEDDING_MODEL: str = "text-embedding-3-small"
    
    # Chunking
    CHUNK_SIZE: int = 500  # tokens
    CHUNK_OVERLAP: float = 0.15  # 15% overlap
    
    # CORS
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080"
    
    @property
    def cors_origins_list(self) -> List[str]:
        """Parse CORS origins from comma-separated string."""
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
