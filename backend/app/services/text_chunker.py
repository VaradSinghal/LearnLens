"""Text chunking service."""
from typing import List, Dict
import tiktoken
from app.config import settings


class TextChunker:
    """Chunk text into smaller pieces for embedding."""
    
    def __init__(self):
        self.chunk_size = settings.CHUNK_SIZE
        self.chunk_overlap = int(settings.CHUNK_SIZE * settings.CHUNK_OVERLAP)
        # Use cl100k_base encoding (used by GPT models)
        self.encoding = tiktoken.get_encoding("cl100k_base")
    
    def chunk_text(self, text: str) -> List[Dict[str, any]]:
        """Chunk text into overlapping segments."""
        # Encode text to tokens
        tokens = self.encoding.encode(text)
        
        chunks = []
        start_idx = 0
        
        while start_idx < len(tokens):
            # Calculate end index
            end_idx = min(start_idx + self.chunk_size, len(tokens))
            
            # Decode chunk
            chunk_tokens = tokens[start_idx:end_idx]
            chunk_text = self.encoding.decode(chunk_tokens)
            
            # Calculate character positions (approximate)
            char_start = self._token_to_char_position(text, start_idx)
            char_end = self._token_to_char_position(text, end_idx)
            
            chunks.append({
                "text": chunk_text,
                "start_char": char_start,
                "end_char": char_end,
                "token_count": len(chunk_tokens),
            })
            
            # Move start index with overlap
            start_idx += self.chunk_size - self.chunk_overlap
            
            # Break if we've reached the end
            if end_idx >= len(tokens):
                break
        
        return chunks
    
    def _token_to_char_position(self, text: str, token_index: int) -> int:
        """Approximate character position from token index."""
        # Simple approximation: assume average token length
        # More accurate would require encoding up to that point
        tokens = self.encoding.encode(text)
        if token_index >= len(tokens):
            return len(text)
        
        # Encode up to token_index and get length
        partial_tokens = tokens[:token_index]
        partial_text = self.encoding.decode(partial_tokens)
        return len(partial_text)

