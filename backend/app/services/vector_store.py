"""Pinecone vector database service."""
from typing import List, Dict, Optional, Any
from uuid import UUID, uuid4
from pinecone import Pinecone, ServerlessSpec
from app.config import settings


class VectorStore:
    """Pinecone vector database operations."""
    
    def __init__(self):
        self._initialize_client()
    
    def _initialize_client(self):
        """Initialize Pinecone client."""
        pc = Pinecone(api_key=settings.PINECONE_API_KEY)
        index_name = settings.PINECONE_INDEX_NAME
        
        # Check if index exists, create if not
        existing_indexes = [idx.name for idx in pc.list_indexes()]
        if index_name not in existing_indexes:
            pc.create_index(
                name=index_name,
                dimension=1536,  # OpenAI embedding dimension
                metric="cosine",
                spec=ServerlessSpec(
                    cloud="aws",
                    region=settings.PINECONE_ENVIRONMENT,
                ),
            )
        
        self.index = pc.Index(index_name)
    
    async def add_chunk(
        self,
        document_id: UUID,
        chunk_id: Optional[UUID],
        text: str,
        embedding: List[float],
        metadata: Dict[str, Any] = None,
    ) -> UUID:
        """Add a chunk to Pinecone. Embedding must be provided."""
        if chunk_id is None:
            chunk_id = uuid4()
        
        if metadata is None:
            metadata = {}
        
        if embedding is None:
            raise ValueError("Pinecone requires embeddings. Use embedding service to generate.")
        
        self.index.upsert(
            vectors=[{
                "id": str(chunk_id),
                "values": embedding,
                "metadata": {
                    **metadata,
                    "document_id": str(document_id),
                    "text": text,
                    "chunk_id": str(chunk_id),
                },
            }]
        )
        
        return chunk_id
    
    async def search(
        self,
        query_embedding: List[float],
        query_text: Optional[str] = None,
        document_id: Optional[UUID] = None,
        top_k: int = 5,
    ) -> List[Dict[str, Any]]:
        """Search for similar chunks using query embedding."""
        if query_embedding is None:
            if query_text:
                # Generate embedding using embedding service
                from app.services.embedding_service import EmbeddingService
                import asyncio
                embedding_service = EmbeddingService()
                query_embedding = asyncio.run(embedding_service.embed_text(query_text))
            else:
                raise ValueError("Pinecone requires query_embedding or query_text with embedding service configured.")
        
        filter_dict = {"document_id": str(document_id)} if document_id else None
        results = self.index.query(
            vector=query_embedding,
            top_k=top_k,
            include_metadata=True,
            filter=filter_dict,
        )
        
        chunks = []
        for match in results.matches:
            chunks.append({
                "chunk_id": UUID(match.id),
                "text": match.metadata.get("text", ""),
                "metadata": match.metadata,
                "distance": match.score,
            })
        return chunks
    
    async def delete_document(self, document_id: UUID):
        """Delete all chunks for a document."""
        self.index.delete(filter={"document_id": str(document_id)})
