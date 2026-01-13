"""Documents router."""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from typing import List
from uuid import UUID
from datetime import datetime
from app.database import get_firestore
from app.schemas import DocumentResponse, DocumentListResponse, UploadResponse
from app.routers.auth import get_current_user
from app.models import Document, DocumentStatus
from app.services.document_processor import DocumentProcessor
from app.services.vector_store import VectorStore

router = APIRouter()


@router.post("/documents/upload", response_model=UploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_document(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """Upload and process a document."""
    # Validate file type - now includes images
    allowed_extensions = {".pdf", ".docx", ".txt", ".jpg", ".jpeg", ".png", ".gif", ".webp"}
    file_extension = "." + file.filename.split(".")[-1].lower() if "." in file.filename else ""
    
    if file_extension not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type. Allowed: {', '.join(allowed_extensions)}"
        )
    
    try:
        db = get_firestore()
    except RuntimeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database not initialized: {str(e)}"
        )
    
    document = None
    doc_ref = None
    
    try:
        # Read file content
        content = await file.read()
        
        if len(content) == 0:
            raise HTTPException(status_code=400, detail="File is empty")
        
        # Create document record
        document = Document(
            user_id=current_user["user_id"],
            title=file.filename,
            extracted_text="",  # Will be updated after processing
            status=DocumentStatus.PROCESSING,
        )
        
        # Save to Firestore
        doc_ref = db.collection(Document.collection_name()).document(str(document.document_id))
        doc_ref.set(document.to_dict())
        
        # Process document (chunk, embed, store in Pinecone and Firestore)
        processor = DocumentProcessor()
        result = await processor.process_document(
            content=content,
            filename=file.filename,
            document_id=str(document.document_id),
            user_id=current_user["user_id"],
        )
        
        # Update document with extracted text and chunks info
        document.extracted_text = result.get("extracted_text", "")
        document.status = DocumentStatus.PROCESSED
        doc_ref.update(document.to_dict())
        
        chunks_count = len(result.get("chunks", []))
        message = f"Document processed successfully. {chunks_count} chunk(s) created and embedded."
        
        return UploadResponse(
            document_id=document.document_id,
            status=document.status,
            message=message,
        )
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        # Mark document as failed
        if document is not None and doc_ref is not None:
            try:
                document.status = DocumentStatus.FAILED
                doc_ref.update(document.to_dict())
            except:
                pass  # If update fails, continue with error
        
        import traceback
        error_details = traceback.format_exc()
        print(f"Document processing error: {error_details}")
        raise HTTPException(status_code=500, detail=f"Processing failed: {str(e)}")


@router.get("/documents", response_model=DocumentListResponse)
async def list_documents(
    skip: int = 0,
    limit: int = 20,
    current_user: dict = Depends(get_current_user),
):
    """List user's documents."""
    try:
        db = get_firestore()
    except RuntimeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database not initialized: {str(e)}"
        )
    
    # Query Firestore
    query = db.collection(Document.collection_name()).where(
        "user_id", "==", current_user["user_id"]
    )
    
    try:
        # Get all documents for total count and pagination
        all_docs = list(query.stream())
        total = len(all_docs)
        
        # Sort by uploaded_at (descending) and apply pagination
        def get_uploaded_at(doc):
            try:
                doc_dict = doc.to_dict()
                uploaded_at = doc_dict.get("uploaded_at")
                if uploaded_at is None:
                    return datetime.min
                if isinstance(uploaded_at, datetime):
                    return uploaded_at
                # Handle Firestore Timestamp
                if hasattr(uploaded_at, 'seconds'):
                    from datetime import timezone
                    return datetime.fromtimestamp(uploaded_at.seconds, tz=timezone.utc)
                # Try to parse if it's a string
                if isinstance(uploaded_at, str):
                    try:
                        return datetime.fromisoformat(uploaded_at.replace('Z', '+00:00'))
                    except:
                        pass
                return datetime.min
            except Exception as e:
                print(f"Error getting uploaded_at for document {doc.id}: {e}")
                return datetime.min
        
        all_docs.sort(key=get_uploaded_at, reverse=True)
        documents = []
        for doc in all_docs[skip:skip + limit]:
            try:
                doc_data = doc.to_dict()
                doc_data["document_id"] = UUID(doc.id)
                document = Document.from_dict(doc_data)
                documents.append(document)
            except Exception as e:
                # Skip documents that can't be parsed
                import traceback
                print(f"Error parsing document {doc.id}: {e}")
                print(traceback.format_exc())
                continue
        
        return DocumentListResponse(
            documents=[DocumentResponse.model_validate(doc) for doc in documents],
            total=total,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing documents: {str(e)}")


@router.get("/documents/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Get a specific document."""
    try:
        db = get_firestore()
    except RuntimeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database not initialized: {str(e)}"
        )
    
    doc_ref = db.collection(Document.collection_name()).document(str(document_id))
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Document not found")
    
    doc_data = doc.to_dict()
    doc_data["document_id"] = UUID(doc.id)
    document = Document.from_dict(doc_data)
    
    # Verify ownership
    if document.user_id != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return DocumentResponse.model_validate(document)


@router.delete("/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    document_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Delete a document and its associated data."""
    try:
        db = get_firestore()
    except RuntimeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database not initialized: {str(e)}"
        )
    
    doc_ref = db.collection(Document.collection_name()).document(str(document_id))
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Document not found")
    
    doc_data = doc.to_dict()
    if doc_data.get("user_id") != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Delete from Pinecone
    vector_store = VectorStore()
    await vector_store.delete_document(document_id)
    
    # Delete chunks from Firestore
    chunks_query = db.collection("chunks").where("document_id", "==", str(document_id))
    for chunk_doc in chunks_query.stream():
        chunk_doc.reference.delete()
    
    # Delete questions from Firestore
    questions_query = db.collection("questions").where("document_id", "==", str(document_id))
    for question_doc in questions_query.stream():
        question_doc.reference.delete()
    
    # Delete document
    doc_ref.delete()
    
    return None
