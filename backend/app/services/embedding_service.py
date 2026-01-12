"""Embedding service for generating vector embeddings."""
from typing import List
from openai import AsyncOpenAI
from anthropic import AsyncAnthropic
import google.generativeai as genai
from app.config import settings


class EmbeddingService:
    """Generate embeddings using various providers."""
    
    def __init__(self):
        self.provider = settings.EMBEDDING_PROVIDER
        self.model = settings.EMBEDDING_MODEL
        
        # Initialize provider clients
        if self.provider == "openai":
            self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        elif self.provider == "anthropic":
            self.anthropic_client = AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
        elif self.provider == "google":
            genai.configure(api_key=settings.GOOGLE_API_KEY)
    
    async def embed_text(self, text: str) -> List[float]:
        """Generate embedding for a single text."""
        if self.provider == "openai":
            response = await self.client.embeddings.create(
                model=self.model,
                input=text,
            )
            return response.data[0].embedding
        
        elif self.provider == "anthropic":
            # Anthropic doesn't have embeddings API, use OpenAI as fallback
            # Or use a different approach
            raise NotImplementedError("Anthropic embeddings not yet implemented")
        
        elif self.provider == "google":
            # Google Generative AI embeddings
            result = genai.embed_content(
                model="models/text-embedding-004",
                content=text,
            )
            return result["embedding"]
        
        else:
            raise ValueError(f"Unknown embedding provider: {self.provider}")
    
    async def embed_batch(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for multiple texts."""
        if self.provider == "openai":
            response = await self.client.embeddings.create(
                model=self.model,
                input=texts,
            )
            return [item.embedding for item in response.data]
        
        elif self.provider == "google":
            results = genai.embed_content(
                model="models/text-embedding-004",
                content=texts,
            )
            return results["embeddings"]
        
        else:
            # Fallback to sequential embedding
            return [await self.embed_text(text) for text in texts]

