"""Authentication router."""
from fastapi import APIRouter, Depends, HTTPException, Header
from typing import Optional
from firebase_admin import auth
from app.database import initialize_firebase

router = APIRouter()

# Ensure Firebase is initialized (safe to call multiple times)
initialize_firebase()


async def verify_firebase_token(authorization: Optional[str] = Header(None, alias="Authorization")):
    """Verify Firebase ID token."""
    # Check if Firebase Admin SDK is initialized
    try:
        firebase_admin.get_app()
    except ValueError:
        raise HTTPException(
            status_code=500, 
            detail="Firebase Admin SDK not initialized. Please check firebase-credentials.json"
        )
    
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header missing")
    
    try:
        # Extract token from "Bearer <token>" (handle both "Bearer token" and just "token")
        if authorization.startswith("Bearer "):
            token = authorization.replace("Bearer ", "").strip()
        else:
            token = authorization.strip()
        
        if not token:
            raise HTTPException(status_code=401, detail="Token is empty")
        
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except HTTPException:
        raise
    except ValueError as e:
        # Token format error
        print(f"Token format error: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid token format")
    except Exception as e:
        import traceback
        error_msg = str(e)
        print(f"Token verification error: {error_msg}")
        print(traceback.format_exc())
        
        # Provide more helpful error messages
        if "expired" in error_msg.lower():
            raise HTTPException(status_code=401, detail="Token has expired. Please log in again.")
        elif "invalid" in error_msg.lower() or "malformed" in error_msg.lower():
            raise HTTPException(status_code=401, detail="Invalid token. Please log in again.")
        else:
            raise HTTPException(status_code=401, detail=f"Authentication failed: {error_msg}")


async def get_current_user(token_data: dict = Depends(verify_firebase_token)):
    """Get current user from token."""
    return {
        "user_id": token_data.get("uid"),
        "email": token_data.get("email"),
    }


@router.get("/auth/me")
async def get_current_user_info(current_user: dict = Depends(get_current_user)):
    """Get current user information."""
    return current_user

