"""Embedding service for generating vector embeddings."""
from typing import List
from openai import AsyncOpenAI
from anthropic import AsyncAnthropic
from google import genai
from app.config import settings


class EmbeddingService:
    """Generate embeddings using various providers."""
    
    def __init__(self):
        self.provider = settings.EMBEDDING_PROVIDER
        self.model = settings.EMBEDDING_MODEL
        
        # Initialize provider clients
        if self.provider == "openai":
            if not settings.OPENAI_API_KEY:
                raise ValueError("OPENAI_API_KEY is required when EMBEDDING_PROVIDER is 'openai'")
            self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        elif self.provider == "anthropic":
            if not settings.ANTHROPIC_API_KEY:
                raise ValueError("ANTHROPIC_API_KEY is required when EMBEDDING_PROVIDER is 'anthropic'")
            self.anthropic_client = AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
        elif self.provider == "google":
            if not settings.GOOGLE_API_KEY:
                raise ValueError("GOOGLE_API_KEY is required when EMBEDDING_PROVIDER is 'google'. Get a free API key from https://makersuite.google.com/app/apikey")
            # Initialize Google GenAI client
            self.google_client = genai.Client(api_key=settings.GOOGLE_API_KEY)
        else:
            raise ValueError(f"Unknown embedding provider: {self.provider}. Supported: 'openai', 'google'")
    
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
            # Google GenAI embeddings using client
            try:
                import asyncio
                loop = asyncio.get_event_loop()
                result = await loop.run_in_executor(
                    None,
                    lambda: self.google_client.models.embed_content(
                        model="text-embedding-004",
                        content=text,
                    )
                )
                if isinstance(result, dict) and "embedding" in result:
                    return result["embedding"]
                elif hasattr(result, "embedding"):
                    return result.embedding
                elif hasattr(result, "values"):
                    return result.values
                else:
                    raise ValueError("Unexpected response format from Google embedding API")
            except Exception as e:
                raise RuntimeError(f"Google embedding API error: {str(e)}. Make sure GOOGLE_API_KEY is valid.")
        
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
            try:
                # Try batch embedding
                import asyncio
                loop = asyncio.get_event_loop()
                results = await loop.run_in_executor(
                    None,
                    lambda: self.google_client.models.embed_content(
                        model="text-embedding-004",
                        content=texts,
                    )
                )
                if isinstance(results, dict) and "embeddings" in results:
                    return results["embeddings"]
                elif hasattr(results, "embeddings"):
                    return results.embeddings
                elif isinstance(results, list):
                    return [item.embedding if hasattr(item, "embedding") else item for item in results]
                else:
                    # Fallback: embed sequentially if batch doesn't work
                    return [await self.embed_text(text) for text in texts]
            except Exception as e:
                # Fallback to sequential embedding on error
                print(f"Google batch embedding error: {e}, falling back to sequential")
                return [await self.embed_text(text) for text in texts]
        
        else:
            # Fallback to sequential embedding
            return [await self.embed_text(text) for text in texts]

