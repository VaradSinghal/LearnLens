"""Questions router."""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from uuid import UUID
from datetime import datetime
from app.database import get_firestore
from app.schemas import QuestionResponse, QuestionListResponse
from app.routers.auth import get_current_user
from app.models import Question, Document, QuestionType, Difficulty
from app.services.question_generator import QuestionGenerator

router = APIRouter()


@router.post("/documents/{document_id}/questions/generate", response_model=List[QuestionResponse], status_code=status.HTTP_201_CREATED)
async def generate_questions(
    document_id: UUID,
    question_type: QuestionType,
    difficulty: Difficulty,
    num_questions: int = 5,
    current_user: dict = Depends(get_current_user),
):
    """Generate questions for a document."""
    try:
        db = get_firestore()
    except RuntimeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database not initialized: {str(e)}"
        )
    
    # Verify document belongs to user
    doc_ref = db.collection(Document.collection_name()).document(str(document_id))
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Document not found")
    
    doc_data = doc.to_dict()
    if doc_data.get("user_id") != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    if doc_data.get("status") != "processed":
        raise HTTPException(
            status_code=400,
            detail=f"Document not ready. Status: {doc_data.get('status')}"
        )
    
    # Check if document has chunks before generating questions
    chunks_query = db.collection("chunks").where("document_id", "==", str(document_id))
    chunks_docs = list(chunks_query.stream())
    
    if not chunks_docs:
        raise HTTPException(
            status_code=400,
            detail="Document has no chunks. Please ensure the document was processed successfully and contains extractable text."
        )
    
    # Generate questions
    generator = QuestionGenerator()
    try:
        questions = await generator.generate_questions(
            document_id=str(document_id),
            question_type=question_type,
            difficulty=difficulty,
            num_questions=num_questions,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e)
        )
    
    # Convert to response format
    question_responses = []
    for question in questions:
        question_responses.append(QuestionResponse(
            question_id=question.question_id,
            document_id=question.document_id,
            question_type=question.question_type,
            difficulty=question.difficulty,
            question_text=question.question_text,
            correct_answer=question.correct_answer,
            explanation=question.explanation,
            options=question.options,
            created_at=question.created_at,
            chunk_ids=[UUID(cid) for cid in question.chunk_ids] if question.chunk_ids else [],
        ))
    
    return question_responses


@router.get("/documents/{document_id}/questions", response_model=QuestionListResponse)
async def list_questions(
    document_id: UUID,
    skip: int = 0,
    limit: int = 20,
    current_user: dict = Depends(get_current_user),
):
    """List questions for a document."""
    try:
        db = get_firestore()
    except RuntimeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database not initialized: {str(e)}"
        )
    
    # Verify document belongs to user
    doc_ref = db.collection(Document.collection_name()).document(str(document_id))
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Document not found")
    
    doc_data = doc.to_dict()
    if doc_data.get("user_id") != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Get questions
    questions_query = db.collection(Question.collection_name()).where(
        "document_id", "==", str(document_id)
    )
    
    all_questions = list(questions_query.stream())
    # Sort by created_at (descending)
    all_questions.sort(key=lambda q: q.to_dict().get("created_at", datetime.min), reverse=True)
    total = len(all_questions)
    questions_docs = all_questions[skip:skip + limit]
    
    # Convert to response format
    question_responses = []
    for q_doc in questions_docs:
        q_data = q_doc.to_dict()
        q_data["question_id"] = UUID(q_doc.id)
        question = Question.from_dict(q_data)
        question_responses.append(QuestionResponse(
            question_id=question.question_id,
            document_id=question.document_id,
            question_type=question.question_type,
            difficulty=question.difficulty,
            question_text=question.question_text,
            correct_answer=question.correct_answer,
            explanation=question.explanation,
            options=question.options,
            created_at=question.created_at,
            chunk_ids=[UUID(cid) for cid in question.chunk_ids] if question.chunk_ids else [],
        ))
    
    return QuestionListResponse(
        questions=question_responses,
        total=total,
    )


@router.get("/questions/{question_id}", response_model=QuestionResponse)
async def get_question(
    question_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Get a specific question."""
    try:
        db = get_firestore()
    except RuntimeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database not initialized: {str(e)}"
        )
    
    q_ref = db.collection(Question.collection_name()).document(str(question_id))
    q_doc = q_ref.get()
    
    if not q_doc.exists:
        raise HTTPException(status_code=404, detail="Question not found")
    
    q_data = q_doc.to_dict()
    q_data["question_id"] = UUID(q_doc.id)
    question = Question.from_dict(q_data)
    
    # Verify document belongs to user
    doc_ref = db.collection(Document.collection_name()).document(str(question.document_id))
    doc = doc_ref.get()
    
    if not doc.exists or doc.to_dict().get("user_id") != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return QuestionResponse(
        question_id=question.question_id,
        document_id=question.document_id,
        question_type=question.question_type,
        difficulty=question.difficulty,
        question_text=question.question_text,
        correct_answer=question.correct_answer,
        explanation=question.explanation,
        options=question.options,
        created_at=question.created_at,
        chunk_ids=[UUID(cid) for cid in question.chunk_ids] if question.chunk_ids else [],
    )
