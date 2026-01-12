"""Firebase Firestore database configuration."""
import firebase_admin
from firebase_admin import credentials, firestore
from app.config import settings
import os


_firebase_app = None
_db = None

def initialize_firebase():
    """Initialize Firebase Admin (only once)."""
    global _firebase_app, _db
    try:
        # Check if Firebase is already initialized
        _firebase_app = firebase_admin.get_app()
        print("Firebase Admin SDK already initialized.")
    except ValueError:
        # Not initialized, so initialize it
        if os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
            try:
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                _firebase_app = firebase_admin.initialize_app(cred)
                print("Firebase Admin SDK initialized successfully.")
            except Exception as e:
                print(f"Error initializing Firebase: {e}")
                _firebase_app = None
        else:
            print(f"Warning: Firebase credentials not found at {settings.FIREBASE_CREDENTIALS_PATH}")
            print("Firebase Admin SDK will not be available. Authentication will fail.")
            _firebase_app = None
    
    # Initialize Firestore client if Firebase is initialized
    if _firebase_app is not None:
        try:
            _db = firestore.client()
            print("Firestore client initialized.")
        except Exception as e:
            print(f"Error initializing Firestore client: {e}")
            _db = None
    else:
        _db = None


# Initialize Firebase
initialize_firebase()

# Get Firestore client
db = _db if _db is not None else None


def get_firestore():
    """Get Firestore database client."""
    if db is None:
        raise RuntimeError(
            "Firestore is not initialized. Please ensure firebase-credentials.json exists "
            "in the backend directory and contains valid Firebase Admin SDK credentials."
        )
    return db
