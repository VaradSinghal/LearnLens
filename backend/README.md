# Learn Lens Backend API

FastAPI backend for the Learn Lens AI learning and assessment platform.

## Architecture

- **FastAPI**: Web framework
- **Firebase Firestore**: Primary database for all textual/structured data
- **Pinecone**: Vector database for embeddings
- **LLMs**: OpenAI/Anthropic/Google for question generation and evaluation
- **Firebase Auth**: User authentication

## Setup

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Configure environment:**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Set up Firebase:**
   - Get Firebase credentials (see `FIREBASE_SETUP.md` if needed)
   - Place `firebase-credentials.json` in the `backend/` directory
   - Set `FIREBASE_PROJECT_ID` in `.env`

4. **Set up Pinecone:**
   - Get Pinecone API key from [Pinecone Console](https://app.pinecone.io/)
   - Set `PINECONE_API_KEY` and `PINECONE_ENVIRONMENT` in `.env`
   - Index will be created automatically on first use

5. **Run the server:**
```bash
python run.py
```

Or with uvicorn directly:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:8000/api/v1/docs
- ReDoc: http://localhost:8000/api/v1/redoc

## Environment Variables

See `.env.example` for all required environment variables:

- **Firebase**: Firebase Admin SDK credentials (for Firestore)
- **Pinecone**: Pinecone API key and configuration
- **LLM Providers**: OpenAI, Anthropic, or Google API keys
- **Embeddings**: Embedding model configuration (required for Pinecone)

## Data Storage

### Firebase Firestore Collections:
- `documents` - Document metadata and extracted text
- `chunks` - Chunk metadata and text
- `questions` - Generated questions
- `attempts` - User attempts and scores

### Pinecone Index:
- `learnlens` - Stores chunk embeddings with metadata

## Key Features

- Document upload and processing (PDF/DOCX/TXT)
- Text chunking and embedding (stored in Pinecone)
- AI-powered question generation
- Answer evaluation (MCQ and descriptive)
- Performance analytics

## Development

```bash
# Run with auto-reload
python run.py

# Or with uvicorn
uvicorn app.main:app --reload

# Run tests (when implemented)
pytest
```

## Notes

- **No database setup required**: Firestore is serverless and schema-less
- **No migrations needed**: Firestore collections are created automatically
- **Pinecone index**: Created automatically on first use
- **Embeddings**: Must be generated using external service (OpenAI/Google) for Pinecone