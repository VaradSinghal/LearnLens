"""Document processing service."""
import io
from typing import Dict, Any
from PyPDF2 import PdfReader
from docx import Document as DocxDocument
from app.services.text_chunker import TextChunker
from app.services.vector_store import VectorStore
from app.services.embedding_service import EmbeddingService
from app.database import get_firestore
from app.models import Chunk
from app.config import settings


class DocumentProcessor:
    """Process uploaded documents."""
    
    def __init__(self):
        self.chunker = TextChunker()
        self.vector_store = VectorStore()
        self.embedding_service = EmbeddingService()
        self.db = get_firestore()
    
    async def process_document(
        self,
        content: bytes,
        filename: str,
        document_id: str,
        user_id: str,
    ) -> Dict[str, Any]:
        """Process a document: extract text, chunk, embed, and store."""
        from uuid import UUID
        doc_uuid = UUID(document_id) if isinstance(document_id, str) else document_id
        
        # Extract text
        extracted_text = self._extract_text(content, filename)
        
        # Clean text
        cleaned_text = self._clean_text(extracted_text)
        
        # If no text extracted (e.g., empty file or image without OCR), return minimal result
        if not cleaned_text or len(cleaned_text.strip()) == 0:
            return {
                "extracted_text": extracted_text if extracted_text else f"[File: {filename} - No text content]",
                "chunks": [],
            }
        
        # Chunk text
        chunks = self.chunker.chunk_text(cleaned_text)
        
        # If no chunks created, return with minimal data
        if not chunks or len(chunks) == 0:
            return {
                "extracted_text": cleaned_text,
                "chunks": [],
            }
        
        # Store chunks in Pinecone and Firestore
        chunk_metadata = []
        for idx, chunk_data in enumerate(chunks):
            try:
                chunk_text = chunk_data.get("text", "").strip()
                if not chunk_text:
                    continue
                
                # Generate embedding for Pinecone
                embedding = await self.embedding_service.embed_text(chunk_text)
                
                # Store in Pinecone
                chunk_id = await self.vector_store.add_chunk(
                    document_id=doc_uuid,
                    chunk_id=None,  # Will be generated
                    text=chunk_text,
                    embedding=embedding,
                    metadata={
                        "chunk_index": idx,
                        "start_char": chunk_data.get("start_char", 0),
                        "end_char": chunk_data.get("end_char", 0),
                        "user_id": user_id,
                    },
                )
                
                # Store chunk metadata in Firestore
                chunk = Chunk(
                    chunk_id=chunk_id,
                    document_id=doc_uuid,
                    chunk_index=idx,
                    start_char=chunk_data.get("start_char", 0),
                    end_char=chunk_data.get("end_char", 0),
                    chunk_text=chunk_text,
                )
                
                self.db.collection(Chunk.collection_name()).document(str(chunk_id)).set(
                    chunk.to_dict()
                )
                
                chunk_metadata.append({
                    "chunk_id": str(chunk_id),
                    "chunk_index": idx,
                    "start_char": chunk_data.get("start_char", 0),
                    "end_char": chunk_data.get("end_char", 0),
                })
            except Exception as e:
                # Log error but continue with other chunks
                print(f"Error processing chunk {idx}: {e}")
                continue
        
        return {
            "extracted_text": cleaned_text,
            "chunks": chunk_metadata,
        }
    
    def _extract_text(self, content: bytes, filename: str) -> str:
        """Extract text from document."""
        file_extension = "." + filename.split(".")[-1].lower() if "." in filename else ""

        if file_extension == ".pdf":
            return self._extract_from_pdf(content)
        elif file_extension == ".docx":
            return self._extract_from_docx(content)
        elif file_extension == ".txt":
            return content.decode("utf-8")
        elif file_extension in {".jpg", ".jpeg", ".png", ".gif", ".webp"}:
            # For images, return a placeholder text indicating it's an image
            # In production, you'd use OCR (e.g., Tesseract, Google Vision API)
            return f"[Image file: {filename}. OCR not implemented yet. Image stored for future processing.]"
        else:
            raise ValueError(f"Unsupported file type: {file_extension}")
    
    def _extract_from_pdf(self, content: bytes) -> str:
        """Extract text from PDF."""
        pdf_file = io.BytesIO(content)
        reader = PdfReader(pdf_file)
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        return text
    
    def _extract_from_docx(self, content: bytes) -> str:
        """Extract text from DOCX."""
        docx_file = io.BytesIO(content)
        doc = DocxDocument(docx_file)
        text = ""
        for paragraph in doc.paragraphs:
            text += paragraph.text + "\n"
        return text
    
    def _clean_text(self, text: str) -> str:
        """Clean extracted text."""
        # Remove excessive whitespace
        lines = text.split("\n")
        cleaned_lines = []
        for line in lines:
            cleaned_line = " ".join(line.split())
            if cleaned_line:
                cleaned_lines.append(cleaned_line)
        
        # Join with single newlines
        cleaned_text = "\n".join(cleaned_lines)
        
        # Remove headers/footers (simple heuristic: very short lines at start/end)
        lines = cleaned_text.split("\n")
        if len(lines) > 10:
            # Remove first and last 2 lines if they're very short
            if len(lines[0]) < 30:
                lines = lines[1:]
            if len(lines[-1]) < 30:
                lines = lines[:-1]
        
        return "\n".join(lines)
