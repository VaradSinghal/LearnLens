"""Document processing service."""
import io
from typing import Dict, Any, Optional
from PyPDF2 import PdfReader
from docx import Document as DocxDocument
from PIL import Image
from app.services.text_chunker import TextChunker
from app.services.vector_store import VectorStore
from app.services.embedding_service import EmbeddingService
from app.database import get_firestore
from app.models import Chunk
from app.config import settings

# Try to import EasyOCR, fallback to None if not available
try:
    import easyocr
    EASYOCR_AVAILABLE = True
except ImportError:
    EASYOCR_AVAILABLE = False
    print("Warning: EasyOCR not installed. Image OCR will not work. Install with: pip install easyocr")


class DocumentProcessor:
    """Process uploaded documents."""
    
    def __init__(self):
        self.chunker = TextChunker()
        self.vector_store = VectorStore()
        self.embedding_service = EmbeddingService()
        self.db = get_firestore()
        # Initialize OCR reader lazily (only when needed)
        self._ocr_reader: Optional[Any] = None
    
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
        from uuid import uuid4
        
        for idx, chunk_data in enumerate(chunks):
            chunk_text = chunk_data.get("text", "").strip()
            if not chunk_text:
                continue
            
            chunk_id = None
            embedding_success = False
            
            try:
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
                embedding_success = True
            except Exception as e:
                # Log error but continue - we'll still store chunk in Firestore
                print(f"Error generating embedding for chunk {idx}: {e}")
                # Generate a chunk_id even if embedding fails
                chunk_id = uuid4()
            
            # Always store chunk metadata in Firestore (even if embedding failed)
            # This ensures questions can still be generated from the text
            try:
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
                print(f"Error storing chunk {idx} in Firestore: {e}")
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
            # Use OCR to extract text from images
            return self._extract_from_image(content, filename)
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
    
    def _extract_from_image(self, content: bytes, filename: str) -> str:
        """Extract text from image using OCR."""
        if not EASYOCR_AVAILABLE:
            return f"[Image file: {filename}. OCR not available. Please install EasyOCR: pip install easyocr]"
        
        try:
            # Initialize OCR reader if not already done (lazy initialization)
            if self._ocr_reader is None:
                print("Initializing EasyOCR reader (this may take a moment on first use - downloading models)...")
                # Use English by default, can be extended to support other languages
                # gpu=False to work on systems without GPU
                # verbose=False to reduce output noise
                self._ocr_reader = easyocr.Reader(['en'], gpu=False, verbose=False)
            
            # Load image from bytes
            image = Image.open(io.BytesIO(content))
            
            # Handle EXIF orientation for mobile camera images
            # Mobile cameras often store images with rotation metadata
            try:
                from PIL import ImageOps
                # Auto-rotate based on EXIF orientation tag
                image = ImageOps.exif_transpose(image)
            except (AttributeError, Exception):
                # No EXIF data or error, continue as-is
                pass
            
            # Convert to RGB if necessary (EasyOCR works best with RGB)
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Optional: Enhance image quality for better OCR
            # Resize if image is too large (OCR works better on reasonable sizes)
            max_dimension = 2000
            if max(image.size) > max_dimension:
                ratio = max_dimension / max(image.size)
                new_size = (int(image.size[0] * ratio), int(image.size[1] * ratio))
                image = image.resize(new_size, Image.Resampling.LANCZOS)
            
            # Convert PIL Image to numpy array for EasyOCR
            import numpy as np
            image_array = np.array(image)
            
            # Perform OCR
            print(f"Performing OCR on image: {filename} (size: {image.size})")
            results = self._ocr_reader.readtext(image_array)
            
            # Extract text from results
            # Each result is a tuple: (bbox, text, confidence)
            extracted_lines = []
            for (bbox, text, confidence) in results:
                # Only include text with reasonable confidence (> 0.5)
                if confidence > 0.5:
                    extracted_lines.append(text.strip())
            
            if extracted_lines:
                extracted_text = "\n".join(extracted_lines)
                print(f"OCR extracted {len(extracted_lines)} text lines from {filename}")
                return extracted_text
            else:
                print(f"No text detected in image: {filename} (or confidence too low)")
                return f"[Image file: {filename}. No text detected in image. Please ensure the image contains clear, readable text.]"
                
        except ImportError as e:
            # Handle missing numpy (required by EasyOCR)
            error_msg = str(e)
            print(f"Missing dependency for OCR: {error_msg}")
            return f"[Image file: {filename}. OCR dependencies not installed. Please install: pip install easyocr numpy]"
        except Exception as e:
            # Log error but don't fail completely
            import traceback
            error_msg = str(e)
            error_trace = traceback.format_exc()
            print(f"OCR error for {filename}: {error_msg}")
            print(f"Traceback: {error_trace}")
            return f"[Image file: {filename}. OCR processing failed: {error_msg}]"
    
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
            if len(lines) > 0 and len(lines[0]) < 30:
                lines = lines[1:]
            if len(lines) > 0 and len(lines[-1]) < 30:
                lines = lines[:-1]
        
        return "\n".join(lines)
