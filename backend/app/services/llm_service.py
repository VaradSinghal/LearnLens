"""LLM service for question generation and evaluation."""
from typing import List, Dict, Any, Optional
from openai import AsyncOpenAI
from anthropic import AsyncAnthropic
from google import genai
from app.config import settings


class LLMService:
    """Service for interacting with LLM providers."""
    
    def __init__(self):
        self.provider = settings.LLM_PROVIDER
        self.model = settings.LLM_MODEL
        
        # Initialize provider clients
        if self.provider == "openai":
            if not settings.OPENAI_API_KEY:
                raise ValueError("OPENAI_API_KEY is required when LLM_PROVIDER is 'openai'")
            self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        elif self.provider == "anthropic":
            if not settings.ANTHROPIC_API_KEY:
                raise ValueError("ANTHROPIC_API_KEY is required when LLM_PROVIDER is 'anthropic'")
            self.anthropic_client = AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
        elif self.provider == "google":
            if not settings.GOOGLE_API_KEY:
                raise ValueError("GOOGLE_API_KEY is required when LLM_PROVIDER is 'google'. Get a free API key from https://makersuite.google.com/app/apikey")
            # Initialize Google GenAI client
            self.google_client = genai.Client(api_key=settings.GOOGLE_API_KEY)
        else:
            raise ValueError(f"Unknown LLM provider: {self.provider}. Supported: 'openai', 'anthropic', 'google'")
    
    async def generate_questions(
        self,
        chunks: List[str],
        question_type: str,
        difficulty: str,
        num_questions: int = 1,
    ) -> List[Dict[str, Any]]:
        """Generate assessment questions from text chunks."""
        # Combine chunks into context
        context = "\n\n".join(chunks)
        
        # Build prompt based on question type
        if question_type == "mcq":
            prompt = self._build_mcq_prompt(context, difficulty, num_questions)
        elif question_type == "short_answer":
            prompt = self._build_short_answer_prompt(context, difficulty, num_questions)
        elif question_type == "long_answer":
            prompt = self._build_long_answer_prompt(context, difficulty, num_questions)
        else:
            raise ValueError(f"Unknown question type: {question_type}")
        
        # Call LLM
        response = await self._call_llm(prompt)
        
        # Parse response
        questions = self._parse_questions(response, question_type)
        
        return questions
    
    def _build_mcq_prompt(self, context: str, difficulty: str, num_questions: int) -> str:
        """Build prompt for MCQ generation."""
        return f"""Generate {num_questions} multiple-choice question(s) from the following text. 
The difficulty level should be {difficulty}.

Text:
{context}

For each question, provide:
1. question_text: The question itself
2. options: An array of exactly 4 options (A, B, C, D)
3. correct_answer: The correct option letter (A, B, C, or D)
4. explanation: A brief explanation of why the correct answer is right

Format your response as JSON array with this structure:
[
  {{
    "question_text": "...",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correct_answer": "A",
    "explanation": "..."
  }}
]

Only return the JSON array, no additional text."""

    def _build_short_answer_prompt(self, context: str, difficulty: str, num_questions: int) -> str:
        """Build prompt for short answer generation."""
        return f"""Generate {num_questions} short-answer question(s) from the following text.
The difficulty level should be {difficulty}. Answers should be 1-2 sentences.

Text:
{context}

For each question, provide:
1. question_text: The question itself
2. correct_answer: The expected answer (1-2 sentences)
3. explanation: A brief explanation or additional context

Format your response as JSON array:
[
  {{
    "question_text": "...",
    "correct_answer": "...",
    "explanation": "..."
  }}
]

Only return the JSON array, no additional text."""

    def _build_long_answer_prompt(self, context: str, difficulty: str, num_questions: int) -> str:
        """Build prompt for long answer generation."""
        return f"""Generate {num_questions} long-answer/essay question(s) from the following text.
The difficulty level should be {difficulty}. Answers should be comprehensive (paragraphs).

Text:
{context}

For each question, provide:
1. question_text: The question itself
2. correct_answer: A model answer or key points that should be covered
3. explanation: Evaluation criteria or rubric

Format your response as JSON array:
[
  {{
    "question_text": "...",
    "correct_answer": "...",
    "explanation": "..."
  }}
]

Only return the JSON array, no additional text."""

    async def evaluate_answer(
        self,
        question: str,
        correct_answer: str,
        user_answer: str,
        question_type: str,
    ) -> Dict[str, Any]:
        """Evaluate a user's answer using LLM."""
        if question_type == "mcq":
            # MCQ is exact match - compare letters (A, B, C, D)
            # Normalize both to uppercase and strip whitespace
            user_letter = user_answer.strip().upper()
            correct_letter = correct_answer.strip().upper()
            
            # Extract first character if answer contains more than just the letter
            if len(user_letter) > 1:
                user_letter = user_letter[0]
            if len(correct_letter) > 1:
                correct_letter = correct_letter[0]
            
            is_correct = user_letter == correct_letter
            return {
                "is_correct": is_correct,
                "score": 1.0 if is_correct else 0.0,
                "feedback": "Correct!" if is_correct else f"Correct answer is {correct_letter}",
            }
        
        # For descriptive answers, use LLM evaluation
        prompt = self._build_evaluation_prompt(question, correct_answer, user_answer, question_type)
        response = await self._call_llm(prompt)
        
        # Parse evaluation
        evaluation = self._parse_evaluation(response)
        return evaluation
    
    def _build_evaluation_prompt(
        self,
        question: str,
        correct_answer: str,
        user_answer: str,
        question_type: str,
    ) -> str:
        """Build prompt for answer evaluation."""
        return f"""Evaluate the following answer to a {question_type} question.

Question: {question}

Expected Answer (or key points): {correct_answer}

User's Answer: {user_answer}

Provide an evaluation with:
1. is_correct: boolean (true if answer is substantially correct)
2. score: float between 0.0 and 1.0 (1.0 = perfect, 0.0 = completely wrong)
3. feedback: brief feedback explaining the score

For short answers, be lenient - partial credit is appropriate.
For long answers, evaluate based on coverage of key points, accuracy, and completeness.

Format your response as JSON:
{{
  "is_correct": true/false,
  "score": 0.0-1.0,
  "feedback": "..."
}}

Only return the JSON, no additional text."""

    async def _call_llm(self, prompt: str) -> str:
        """Call the LLM with a prompt."""
        if self.provider == "openai":
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are an expert educational content creator and evaluator."},
                    {"role": "user", "content": prompt},
                ],
                temperature=0.7,
            )
            return response.choices[0].message.content
        
        elif self.provider == "anthropic":
            message = await self.anthropic_client.messages.create(
                model=self.model,
                max_tokens=4000,
                messages=[
                    {"role": "user", "content": prompt},
                ],
            )
            return message.content[0].text
        
        elif self.provider == "google":
            try:
                # Google GenAI uses client.models.generate_content
                # Model names: gemini-2.0-flash, gemini-2.0-flash-exp, gemini-1.5-pro, etc.
                model_name = self.model.replace('models/', '') if self.model.startswith('models/') else self.model
                
                # Run synchronous call in executor for async compatibility
                import asyncio
                loop = asyncio.get_event_loop()
                response = await loop.run_in_executor(
                    None,
                    lambda: self.google_client.models.generate_content(
                        model=model_name,
                        contents=prompt
                    )
                )
                
                # Handle response structure
                if hasattr(response, 'text'):
                    return response.text
                elif hasattr(response, 'candidates') and len(response.candidates) > 0:
                    if hasattr(response.candidates[0], 'content') and hasattr(response.candidates[0].content, 'parts'):
                        return response.candidates[0].content.parts[0].text
                    elif hasattr(response.candidates[0], 'text'):
                        return response.candidates[0].text
                else:
                    raise ValueError("Unexpected response format from Google API")
            except Exception as e:
                error_msg = str(e)
                # Provide helpful error message with available models
                if "404" in error_msg or "not found" in error_msg.lower() or "NOT_FOUND" in error_msg:
                    # Try to list available models
                    try:
                        import asyncio
                        loop = asyncio.get_event_loop()
                        models = await loop.run_in_executor(
                            None,
                            lambda: list(self.google_client.models.list())
                        )
                        available_models = [m.name.split('/')[-1] for m in models[:10]]  # Get first 10 model names
                        models_str = ", ".join(available_models) if available_models else "gemini-2.0-flash, gemini-1.5-pro"
                    except:
                        models_str = "gemini-2.0-flash, gemini-1.5-pro, gemini-pro"
                    
                    raise RuntimeError(
                        f"Google model '{self.model}' not found. "
                        f"Available models: {models_str}. "
                        f"Error: {error_msg}"
                    )
                raise RuntimeError(f"Google API error: {error_msg}. Make sure GOOGLE_API_KEY is valid.")
        
        else:
            raise ValueError(f"Unknown LLM provider: {self.provider}")
    
    def _parse_questions(self, response: str, question_type: str) -> List[Dict[str, Any]]:
        """Parse LLM response into question objects."""
        import json
        import re
        
        # Extract JSON from response (handle markdown code blocks)
        json_match = re.search(r'\[.*\]', response, re.DOTALL)
        if json_match:
            json_str = json_match.group(0)
        else:
            json_str = response
        
        try:
            questions = json.loads(json_str)
            if not isinstance(questions, list):
                questions = [questions]
            return questions
        except json.JSONDecodeError:
            # Fallback: try to extract individual questions
            return [{"error": "Failed to parse questions"}]
    
    def _parse_evaluation(self, response: str) -> Dict[str, Any]:
        """Parse evaluation response."""
        import json
        import re
        
        # Extract JSON from response
        json_match = re.search(r'\{.*\}', response, re.DOTALL)
        if json_match:
            json_str = json_match.group(0)
        else:
            json_str = response
        
        try:
            evaluation = json.loads(json_str)
            return evaluation
        except json.JSONDecodeError:
            return {
                "is_correct": False,
                "score": 0.0,
                "feedback": "Evaluation parsing failed",
            }

