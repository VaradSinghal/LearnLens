"""Analytics router."""
from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from uuid import UUID
from datetime import datetime, timedelta
from app.database import get_firestore
from app.schemas import PerformanceAnalytics, TopicAccuracy, DifficultyStats
from app.routers.auth import get_current_user
from app.models import Attempt, Question, Chunk, Document, Difficulty

router = APIRouter()


@router.get("/analytics/performance", response_model=PerformanceAnalytics)
async def get_performance_analytics(
    document_id: Optional[UUID] = None,
    current_user: dict = Depends(get_current_user),
):
    """Get comprehensive performance analytics."""
    db = get_firestore()
    user_id = current_user["user_id"]
    
    # Get user's attempts
    base_attempts_query = db.collection(Attempt.collection_name()).where(
        "user_id", "==", user_id
    )
    
    # Filter by document if provided
    question_ids = None
    if document_id:
        # Verify document belongs to user
        doc_ref = db.collection(Document.collection_name()).document(str(document_id))
        doc = doc_ref.get()
        if not doc.exists or doc.to_dict().get("user_id") != user_id:
            raise HTTPException(status_code=404, detail="Document not found")
        
        # Get question IDs for this document
        questions_query = db.collection(Question.collection_name()).where(
            "document_id", "==", str(document_id)
        )
        question_ids = [q.id for q in questions_query.stream()]
    
    # Get attempts
    if question_ids and len(question_ids) <= 10:
        # Use Firestore "in" query (supports up to 10 items)
        attempts_docs = list(base_attempts_query.where(
            "question_id", "in", question_ids
        ).stream())
    else:
        # Get all attempts and filter in memory if needed
        all_attempts = list(base_attempts_query.stream())
        if question_ids:
            attempts_docs = [
                a for a in all_attempts 
                if a.to_dict().get("question_id") in question_ids
            ]
        else:
            attempts_docs = all_attempts
    
    if not attempts_docs:
        return PerformanceAnalytics(
            total_attempts=0,
            overall_accuracy=0.0,
            topic_accuracy=[],
            difficulty_stats=[],
            weak_areas=[],
            avg_time_per_question=None,
            progress_over_time=[],
        )
    
    # Convert to Attempt objects
    attempts = []
    question_ids = []
    for attempt_doc in attempts_docs:
        attempt_data = attempt_doc.to_dict()
        attempt_data["attempt_id"] = UUID(attempt_doc.id)
        attempts.append(Attempt.from_dict(attempt_data))
        question_ids.append(attempt_data.get("question_id"))
    
    # Calculate overall accuracy
    total_attempts = len(attempts)
    correct_attempts = sum(1 for a in attempts if a.is_correct)
    overall_accuracy = correct_attempts / total_attempts if total_attempts > 0 else 0.0
    
    # Get questions for attempts
    questions_dict = {}
    for q_id in question_ids:
        q_ref = db.collection(Question.collection_name()).document(str(q_id))
        q_doc = q_ref.get()
        if q_doc.exists:
            q_data = q_doc.to_dict()
            q_data["question_id"] = UUID(q_doc.id)
            questions_dict[q_id] = Question.from_dict(q_data)
    
    # Calculate difficulty stats
    difficulty_stats_map = {}
    for attempt in attempts:
        question = questions_dict.get(attempt.question_id)
        if not question:
            continue
        
        difficulty = question.difficulty.value
        if difficulty not in difficulty_stats_map:
            difficulty_stats_map[difficulty] = {
                "total": 0,
                "correct": 0,
                "times": [],
            }
        
        difficulty_stats_map[difficulty]["total"] += 1
        if attempt.is_correct:
            difficulty_stats_map[difficulty]["correct"] += 1
        if attempt.time_taken:
            difficulty_stats_map[difficulty]["times"].append(attempt.time_taken)
    
    difficulty_stats_list = []
    for difficulty, stats in difficulty_stats_map.items():
        accuracy = stats["correct"] / stats["total"] if stats["total"] > 0 else 0.0
        avg_time = sum(stats["times"]) / len(stats["times"]) if stats["times"] else None
        
        difficulty_stats_list.append(DifficultyStats(
            difficulty=Difficulty(difficulty),
            total_questions=stats["total"],
            correct_answers=stats["correct"],
            accuracy=accuracy,
            avg_time=avg_time,
        ))
    
    # Calculate topic accuracy (simplified - using "General" if no topic)
    topic_stats_map = {"General": {"total": 0, "correct": 0}}
    for attempt in attempts:
        question = questions_dict.get(attempt.question_id)
        if not question:
            continue
        
        # For now, use "General" as topic (can be enhanced later)
        topic = "General"
        if topic not in topic_stats_map:
            topic_stats_map[topic] = {"total": 0, "correct": 0}
        
        topic_stats_map[topic]["total"] += 1
        if attempt.is_correct:
            topic_stats_map[topic]["correct"] += 1
    
    topic_accuracy_list = []
    for topic, stats in topic_stats_map.items():
        accuracy = stats["correct"] / stats["total"] if stats["total"] > 0 else 0.0
        topic_accuracy_list.append(TopicAccuracy(
            topic=topic,
            total_questions=stats["total"],
            correct_answers=stats["correct"],
            accuracy=accuracy,
        ))
    
    # Identify weak areas
    weak_areas = [
        ta.topic for ta in topic_accuracy_list
        if ta.accuracy < 0.6 and ta.total_questions >= 3
    ]
    
    # Calculate average time per question
    times = [a.time_taken for a in attempts if a.time_taken]
    avg_time_per_question = sum(times) / len(times) if times else None
    
    # Calculate progress over time (last 30 days)
    progress_data = []
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=30)
    
    date_accuracy = {}
    for attempt in attempts:
        if attempt.attempted_at >= start_date:
            date_key = attempt.attempted_at.date().isoformat()
            if date_key not in date_accuracy:
                date_accuracy[date_key] = {"total": 0, "correct": 0}
            
            date_accuracy[date_key]["total"] += 1
            if attempt.is_correct:
                date_accuracy[date_key]["correct"] += 1
    
    for date_str, stats in sorted(date_accuracy.items()):
        accuracy = stats["correct"] / stats["total"] if stats["total"] > 0 else 0.0
        progress_data.append({
            "date": date_str,
            "accuracy": accuracy,
        })
    
    return PerformanceAnalytics(
        total_attempts=total_attempts,
        overall_accuracy=overall_accuracy,
        topic_accuracy=topic_accuracy_list,
        difficulty_stats=difficulty_stats_list,
        weak_areas=weak_areas,
        avg_time_per_question=avg_time_per_question,
        progress_over_time=progress_data,
    )


@router.get("/analytics/document/{document_id}/summary")
async def get_document_summary(
    document_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Get summary analytics for a specific document."""
    db = get_firestore()
    
    # Verify document belongs to user
    doc_ref = db.collection(Document.collection_name()).document(str(document_id))
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Document not found")
    
    doc_data = doc.to_dict()
    if doc_data.get("user_id") != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Get performance analytics for this document
    analytics = await get_performance_analytics(
        document_id=document_id,
        current_user=current_user,
    )
    
    # Get question counts
    questions_query = db.collection(Question.collection_name()).where(
        "document_id", "==", str(document_id)
    )
    total_questions = len(list(questions_query.stream()))
    
    return {
        "document_id": document_id,
        "title": doc_data.get("title", ""),
        "total_questions": total_questions,
        "analytics": analytics,
    }
