"""Firestore data models and helpers."""
from typing import Optional, List
from datetime import datetime
from uuid import UUID, uuid4
import enum
from google.cloud.firestore import Client as FirestoreClient


class DocumentStatus(str, enum.Enum):
    """Document processing status."""
    UPLOADED = "uploaded"
    PROCESSING = "processing"
    PROCESSED = "processed"
    FAILED = "failed"


class QuestionType(str, enum.Enum):
    """Question type."""
    MCQ = "mcq"
    SHORT_ANSWER = "short_answer"
    LONG_ANSWER = "long_answer"


class Difficulty(str, enum.Enum):
    """Question difficulty."""
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"


class FirestoreModel:
    """Base class for Firestore models."""
    
    @classmethod
    def collection_name(cls) -> str:
        """Get the Firestore collection name."""
        return cls.__name__.lower() + "s"
    
    def to_dict(self) -> dict:
        """Convert model to dictionary for Firestore."""
        data = {}
        for key, value in self.__dict__.items():
            if not key.startswith('_'):
                if isinstance(value, UUID):
                    data[key] = str(value)
                elif isinstance(value, datetime):
                    data[key] = value
                elif isinstance(value, enum.Enum):
                    data[key] = value.value
                elif isinstance(value, list):
                    # Handle lists (e.g., options, chunk_ids)
                    data[key] = [str(v) if isinstance(v, UUID) else v for v in value]
                else:
                    data[key] = value
        return data
    
    @classmethod
    def from_dict(cls, data: dict):
        """Create model from Firestore dictionary."""
        instance = cls.__new__(cls)
        for key, value in data.items():
            if not key.startswith('_'):
                # Handle UUID fields
                if key.endswith('_id') and isinstance(value, str):
                    try:
                        setattr(instance, key, UUID(value))
                    except (ValueError, AttributeError):
                        setattr(instance, key, value)
                # Handle datetime
                elif isinstance(value, datetime):
                    setattr(instance, key, value)
                # Handle Firestore Timestamp
                elif hasattr(value, 'timestamp') or (hasattr(value, 'seconds') and hasattr(value, 'nanoseconds')):  # Firestore Timestamp
                    try:
                        # Firestore Timestamp object
                        if hasattr(value, 'seconds'):
                            from datetime import timezone
                            timestamp = datetime.fromtimestamp(value.seconds, tz=timezone.utc)
                            setattr(instance, key, timestamp)
                        else:
                            setattr(instance, key, datetime.utcnow())
                    except Exception as e:
                        # Fallback to current time if conversion fails
                        setattr(instance, key, datetime.utcnow())
                # Handle enum
                elif key in ['status', 'question_type', 'difficulty']:
                    if key == 'status':
                        from app.models import DocumentStatus
                        setattr(instance, key, DocumentStatus(value))
                    elif key == 'question_type':
                        from app.models import QuestionType
                        setattr(instance, key, QuestionType(value))
                    elif key == 'difficulty':
                        from app.models import Difficulty
                        setattr(instance, key, Difficulty(value))
                else:
                    setattr(instance, key, value)
        return instance


class Document(FirestoreModel):
    """Document model."""
    
    def __init__(
        self,
        document_id: Optional[UUID] = None,
        user_id: str = "",
        title: str = "",
        extracted_text: str = "",
        language: str = "en",
        uploaded_at: Optional[datetime] = None,
        status: DocumentStatus = DocumentStatus.UPLOADED,
    ):
        self.document_id = document_id or uuid4()
        self.user_id = user_id
        self.title = title
        self.extracted_text = extracted_text
        self.language = language
        self.uploaded_at = uploaded_at or datetime.utcnow()
        self.status = status
    
    @classmethod
    def collection_name(cls) -> str:
        return "documents"


class Chunk(FirestoreModel):
    """Text chunk model."""
    
    def __init__(
        self,
        chunk_id: Optional[UUID] = None,
        document_id: Optional[UUID] = None,
        chunk_index: int = 0,
        start_char: int = 0,
        end_char: int = 0,
        chunk_text: Optional[str] = None,
        topic: Optional[str] = None,
        created_at: Optional[datetime] = None,
    ):
        self.chunk_id = chunk_id or uuid4()
        self.document_id = document_id
        self.chunk_index = chunk_index
        self.start_char = start_char
        self.end_char = end_char
        self.chunk_text = chunk_text
        self.topic = topic
        self.created_at = created_at or datetime.utcnow()
    
    @classmethod
    def collection_name(cls) -> str:
        return "chunks"


class Question(FirestoreModel):
    """Assessment question model."""
    
    def __init__(
        self,
        question_id: Optional[UUID] = None,
        document_id: Optional[UUID] = None,
        question_type: QuestionType = QuestionType.MCQ,
        difficulty: Difficulty = Difficulty.MEDIUM,
        question_text: str = "",
        correct_answer: str = "",
        explanation: Optional[str] = None,
        options: Optional[List[str]] = None,
        chunk_ids: Optional[List[UUID]] = None,
        created_at: Optional[datetime] = None,
    ):
        self.question_id = question_id or uuid4()
        self.document_id = document_id
        self.question_type = question_type
        self.difficulty = difficulty
        self.question_text = question_text
        self.correct_answer = correct_answer
        self.explanation = explanation
        self.options = options or []
        self.chunk_ids = [str(cid) for cid in (chunk_ids or [])]
        self.created_at = created_at or datetime.utcnow()
    
    @classmethod
    def collection_name(cls) -> str:
        return "questions"


class Attempt(FirestoreModel):
    """User attempt on a question."""
    
    def __init__(
        self,
        attempt_id: Optional[UUID] = None,
        user_id: str = "",
        question_id: Optional[UUID] = None,
        user_answer: str = "",
        is_correct: bool = False,
        score: Optional[float] = None,
        time_taken: Optional[float] = None,
        attempted_at: Optional[datetime] = None,
    ):
        self.attempt_id = attempt_id or uuid4()
        self.user_id = user_id
        self.question_id = question_id
        self.user_answer = user_answer
        self.is_correct = is_correct
        self.score = score
        self.time_taken = time_taken
        self.attempted_at = attempted_at or datetime.utcnow()
    
    @classmethod
    def collection_name(cls) -> str:
        return "attempts"
