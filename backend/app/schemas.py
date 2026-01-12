"""Pydantic schemas for request/response validation."""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from uuid import UUID
from app.models import DocumentStatus, QuestionType, Difficulty


# Document Schemas
class DocumentBase(BaseModel):
    """Base document schema."""
    title: str = Field(..., max_length=500)
    language: str = Field(default="en", max_length=10)


class DocumentCreate(DocumentBase):
    """Schema for document creation."""
    pass


class DocumentResponse(DocumentBase):
    """Schema for document response."""
    document_id: UUID
    user_id: str
    extracted_text: str
    uploaded_at: datetime
    status: DocumentStatus
    
    class Config:
        from_attributes = True


class DocumentListResponse(BaseModel):
    """Schema for document list response."""
    documents: List[DocumentResponse]
    total: int


# Chunk Schemas
class ChunkResponse(BaseModel):
    """Schema for chunk response."""
    chunk_id: UUID
    document_id: UUID
    chunk_index: int
    start_char: int
    end_char: int
    topic: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


# Question Schemas
class QuestionBase(BaseModel):
    """Base question schema."""
    question_type: QuestionType
    difficulty: Difficulty
    question_text: str
    correct_answer: str
    explanation: Optional[str] = None
    options: Optional[List[str]] = None


class QuestionCreate(QuestionBase):
    """Schema for question creation."""
    document_id: UUID
    chunk_ids: List[UUID]


class QuestionResponse(QuestionBase):
    """Schema for question response."""
    question_id: UUID
    document_id: UUID
    created_at: datetime
    chunk_ids: List[UUID]
    
    class Config:
        from_attributes = True


class QuestionListResponse(BaseModel):
    """Schema for question list response."""
    questions: List[QuestionResponse]
    total: int


# Attempt Schemas
class AttemptCreate(BaseModel):
    """Schema for attempt creation."""
    question_id: UUID
    user_answer: str
    time_taken: Optional[float] = None


class AttemptResponse(BaseModel):
    """Schema for attempt response."""
    attempt_id: UUID
    user_id: str
    question_id: UUID
    user_answer: str
    is_correct: bool
    score: Optional[float] = None
    time_taken: Optional[float] = None
    attempted_at: datetime
    correct_answer: str
    explanation: Optional[str] = None
    
    class Config:
        from_attributes = True


# Analytics Schemas
class TopicAccuracy(BaseModel):
    """Schema for topic accuracy."""
    topic: str
    total_questions: int
    correct_answers: int
    accuracy: float


class DifficultyStats(BaseModel):
    """Schema for difficulty statistics."""
    difficulty: Difficulty
    total_questions: int
    correct_answers: int
    accuracy: float
    avg_time: Optional[float] = None


class PerformanceAnalytics(BaseModel):
    """Schema for performance analytics."""
    total_attempts: int
    overall_accuracy: float
    topic_accuracy: List[TopicAccuracy]
    difficulty_stats: List[DifficultyStats]
    weak_areas: List[str]
    avg_time_per_question: Optional[float] = None
    progress_over_time: List[dict]  # [{date: str, accuracy: float}]


# Upload Schemas
class UploadResponse(BaseModel):
    """Schema for upload response."""
    document_id: UUID
    status: DocumentStatus
    message: str

