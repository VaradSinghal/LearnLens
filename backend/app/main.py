"""FastAPI application entry point."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routers import documents, questions, attempts, analytics, auth

# Initialize FastAPI app
app = FastAPI(
    title="Learn Lens API",
    description="AI-powered learning and assessment platform",
    version="1.0.0",
    docs_url=f"{settings.API_PREFIX}/docs",
    redoc_url=f"{settings.API_PREFIX}/redoc",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix=settings.API_PREFIX, tags=["Authentication"])
app.include_router(documents.router, prefix=settings.API_PREFIX, tags=["Documents"])
app.include_router(questions.router, prefix=settings.API_PREFIX, tags=["Questions"])
app.include_router(attempts.router, prefix=settings.API_PREFIX, tags=["Attempts"])
app.include_router(analytics.router, prefix=settings.API_PREFIX, tags=["Analytics"])


@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Learn Lens API", "version": "1.0.0"}


@app.get(f"{settings.API_PREFIX}/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}
