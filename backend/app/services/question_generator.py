"""Question generation service."""
from typing import List
from uuid import UUID
from app.models import Question, Chunk, Document
from app.services.llm_service import LLMService
from app.database import get_firestore
from app.schemas import QuestionType, Difficulty


class QuestionGenerator:
    """Generate assessment questions from documents."""
    
    def __init__(self):
        self.llm_service = LLMService()
        self.db = get_firestore()
    
    async def generate_questions(
        self,
        document_id: str,
        question_type: QuestionType,
        difficulty: Difficulty,
        num_questions: int,
    ) -> List[Question]:
        """Generate questions for a document."""
        # Get document chunks from Firestore
        # Note: Using simple query without order_by to avoid requiring composite index
        chunks_query = self.db.collection(Chunk.collection_name()).where(
            "document_id", "==", document_id
        )
        
        chunks_docs = list(chunks_query.stream())
        
        # Sort chunks by chunk_index in memory (avoids requiring Firestore composite index)
        chunks_docs.sort(key=lambda doc: doc.to_dict().get("chunk_index", 0))
        
        if not chunks_docs:
            raise ValueError("No chunks found for document. The document may not have been processed successfully or contains no extractable text.")
        
        # Get chunk texts
        chunk_texts = []
        valid_chunk_ids = []
        for chunk_doc in chunks_docs:
            chunk_data = chunk_doc.to_dict()
            if chunk_data.get("chunk_text"):
                chunk_texts.append(chunk_data["chunk_text"])
                valid_chunk_ids.append(chunk_doc.id)
            else:
                # Fallback: get from document
                doc_ref = self.db.collection(Document.collection_name()).document(document_id)
                doc = doc_ref.get()
                if doc.exists:
                    doc_data = doc.to_dict()
                    start_char = chunk_data.get("start_char", 0)
                    end_char = chunk_data.get("end_char", 0)
                    chunk_text = doc_data.get("extracted_text", "")[start_char:end_char]
                    chunk_texts.append(chunk_text)
                    valid_chunk_ids.append(chunk_doc.id)
        
        if not chunk_texts:
            raise ValueError("Could not retrieve chunk texts. The document chunks may be corrupted or missing text content.")
        
        # Generate questions using LLM
        questions_data = await self.llm_service.generate_questions(
            chunks=chunk_texts,
            question_type=question_type.value,
            difficulty=difficulty.value,
            num_questions=num_questions,
        )
        
        # Create question records in Firestore
        created_questions = []
        for q_data in questions_data:
            # Use first few chunks for association
            chunk_ids = valid_chunk_ids[:min(3, len(valid_chunk_ids))]
            
            question = Question(
                document_id=UUID(document_id),
                question_type=question_type,
                difficulty=difficulty,
                question_text=q_data.get("question_text", ""),
                correct_answer=q_data.get("correct_answer", ""),
                explanation=q_data.get("explanation", ""),
                options=q_data.get("options", None),
                chunk_ids=[UUID(cid) for cid in chunk_ids],
            )
            
            # Save to Firestore
            q_ref = self.db.collection(Question.collection_name()).document(str(question.question_id))
            q_ref.set(question.to_dict())
            
            created_questions.append(question)
        
        return created_questions
