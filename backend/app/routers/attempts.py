"""Attempts router."""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from uuid import UUID
from datetime import datetime
from app.database import get_firestore
from app.schemas import AttemptResponse, AttemptCreate
from app.routers.auth import get_current_user
from app.models import Attempt, Question, Document
from app.services.llm_service import LLMService

router = APIRouter()


@router.post("/attempts", response_model=AttemptResponse, status_code=status.HTTP_201_CREATED)
async def submit_attempt(
    attempt_data: AttemptCreate,
    current_user: dict = Depends(get_current_user),
):
    """Submit an answer attempt."""
    try:
        db = get_firestore()
    except RuntimeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database not initialized: {str(e)}"
        )
    
    # Get question
    q_ref = db.collection(Question.collection_name()).document(str(attempt_data.question_id))
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
    
    # Evaluate answer
    llm_service = LLMService()
    evaluation = await llm_service.evaluate_answer(
        question=question.question_text,
        correct_answer=question.correct_answer,
        user_answer=attempt_data.user_answer,
        question_type=question.question_type.value,
    )
    
    # Create attempt record
    attempt = Attempt(
        user_id=current_user["user_id"],
        question_id=attempt_data.question_id,
        user_answer=attempt_data.user_answer,
        is_correct=evaluation["is_correct"],
        score=evaluation.get("score", 1.0 if evaluation["is_correct"] else 0.0),
        time_taken=attempt_data.time_taken,
    )
    
    # Save to Firestore
    attempt_ref = db.collection(Attempt.collection_name()).document(str(attempt.attempt_id))
    attempt_ref.set(attempt.to_dict())
    
    return AttemptResponse(
        attempt_id=attempt.attempt_id,
        user_id=attempt.user_id,
        question_id=attempt.question_id,
        user_answer=attempt.user_answer,
        is_correct=attempt.is_correct,
        score=attempt.score,
        time_taken=attempt.time_taken,
        attempted_at=attempt.attempted_at,
        correct_answer=question.correct_answer,
        explanation=question.explanation,
    )


@router.get("/attempts", response_model=List[AttemptResponse])
async def list_attempts(
    question_id: Optional[UUID] = None,
    skip: int = 0,
    limit: int = 20,
    current_user: dict = Depends(get_current_user),
):
    """List user's attempts."""
    try:
        db = get_firestore()
    except RuntimeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database not initialized: {str(e)}"
        )
    
    query = db.collection(Attempt.collection_name()).where(
        "user_id", "==", current_user["user_id"]
    )
    
    if question_id:
        query = query.where("question_id", "==", str(question_id))
    
    all_attempts = list(query.stream())
    # Sort by attempted_at (descending)
    all_attempts.sort(key=lambda a: a.to_dict().get("attempted_at", datetime.min), reverse=True)
    attempts_docs = all_attempts[skip:skip + limit]
    
    # Get questions for each attempt
    attempt_responses = []
    for attempt_doc in attempts_docs:
        attempt_data = attempt_doc.to_dict()
        attempt_data["attempt_id"] = UUID(attempt_doc.id)
        attempt = Attempt.from_dict(attempt_data)
        
        # Get question
        q_ref = db.collection(Question.collection_name()).document(str(attempt.question_id))
        q_doc = q_ref.get()
        
        question = None
        if q_doc.exists:
            q_data = q_doc.to_dict()
            q_data["question_id"] = UUID(q_doc.id)
            question = Question.from_dict(q_data)
        
        attempt_responses.append(AttemptResponse(
            attempt_id=attempt.attempt_id,
            user_id=attempt.user_id,
            question_id=attempt.question_id,
            user_answer=attempt.user_answer,
            is_correct=attempt.is_correct,
            score=attempt.score,
            time_taken=attempt.time_taken,
            attempted_at=attempt.attempted_at,
            correct_answer=question.correct_answer if question else "",
            explanation=question.explanation if question else None,
        ))
    
    return attempt_responses


@router.get("/attempts/{attempt_id}", response_model=AttemptResponse)
async def get_attempt(
    attempt_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Get a specific attempt."""
    try:
        db = get_firestore()
    except RuntimeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Database not initialized: {str(e)}"
        )
    
    attempt_ref = db.collection(Attempt.collection_name()).document(str(attempt_id))
    attempt_doc = attempt_ref.get()
    
    if not attempt_doc.exists:
        raise HTTPException(status_code=404, detail="Attempt not found")
    
    attempt_data = attempt_doc.to_dict()
    if attempt_data.get("user_id") != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    attempt_data["attempt_id"] = UUID(attempt_doc.id)
    attempt = Attempt.from_dict(attempt_data)
    
    # Get question
    q_ref = db.collection(Question.collection_name()).document(str(attempt.question_id))
    q_doc = q_ref.get()
    
    question = None
    if q_doc.exists:
        q_data = q_doc.to_dict()
        q_data["question_id"] = UUID(q_doc.id)
        question = Question.from_dict(q_data)
    
    return AttemptResponse(
        attempt_id=attempt.attempt_id,
        user_id=attempt.user_id,
        question_id=attempt.question_id,
        user_answer=attempt.user_answer,
        is_correct=attempt.is_correct,
        score=attempt.score,
        time_taken=attempt.time_taken,
        attempted_at=attempt.attempted_at,
        correct_answer=question.correct_answer if question else "",
        explanation=question.explanation if question else None,
    )
