import uuid
from typing import Optional
from datetime import datetime

from fastapi import APIRouter, HTTPException, Depends, status, BackgroundTasks
from fastapi.security import OAuth2PasswordRequestForm

from ..auth.auth_manager import auth_manager
from ..auth.dependencies import require_auth, require_admin
from ...memory.models import User

router = APIRouter()

@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register_user(
    username: str, 
    email: str, 
    password: str, 
    full_name: Optional[str] = None, 
    is_admin: bool = False
):
    user = await auth_manager.create_user(username, email, password, full_name, is_admin)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this username or email already exists"
        )
    return {"message": "User registered successfully", "user_id": str(user.id)}

@router.post("/login")
async def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(),
    background_tasks: BackgroundTasks = None
):
    user = await auth_manager.authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password"
        )
    session = await auth_manager.create_session(user.id)
    if background_tasks:
        background_tasks.add_task(auth_manager.create_session, user.id)
    return {
        "access_token": session.session_token,
        "token_type": "bearer",
        "expires_at": session.expires_at.isoformat()
    }

@router.post("/logout")
async def logout_user(current_user: User = Depends(require_auth)):
    session_token = getattr(current_user, "session_token", None)
    success = await auth_manager.invalidate_session(session_token)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to log out"
        )
    return {"message": "Logged out successfully"}

@router.get("/me")
async def get_current_user_info(current_user: User = Depends(require_auth)):
    return current_user.to_dict()

@router.get("/users")
async def get_all_users(current_user: User = Depends(require_admin)):
    users = await auth_manager.get_all_users()
    return {"users": [user.to_dict() for user in users]}

@router.post("/invite")
async def invite_user(
    email: str, 
    current_user: User = Depends(require_admin)
):
    invitation = await auth_manager.create_invitation(email, current_user.id)
    if not invitation:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create invitation"
        )
    return {"message": "Invitation created successfully", "invitation_token": invitation.invitation_token}

@router.get("/invitation/{invitation_token}")
async def accept_invitation(invitation_token: str):
    invitation = await auth_manager.get_invitation_by_token(invitation_token)
    if not invitation or invitation.is_used:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or used invitation token"
        )
    invitation.is_used = True
    invitation.used_at = datetime.utcnow()
    user = await auth_manager.create_user(
        username=invitation.email.split('@')[0],
        email=invitation.email,
        password=str(uuid.uuid4())[:8],
        full_name=None,
        is_admin=False
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create user from invitation"
        )
    return {"message": "User created successfully from invitation", "user_id": str(user.id)}

@router.get("/session")
async def get_user_session_info(current_user: User = Depends(require_auth)):
    session = await auth_manager.get_user_session(getattr(current_user, "session_token", None))
    if not session:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session not found"
        )
    return {
        "session_token": session.session_token,
        "expires_at": session.expires_at.isoformat(),
        "last_used": session.last_used.isoformat(),
        "is_active": session.is_active
    }
