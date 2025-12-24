import logging
from typing import Optional, Union

from fastapi import Depends, HTTPException, status, Cookie, Request, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from ...memory.models import User
from .auth_manager import auth_manager

logger = logging.getLogger(__name__)

security = HTTPBearer(auto_error=False)

async def get_session_token(
    request: Request,
    session_token: Optional[str] = Cookie(None, alias="session_token"),
    authorization: Optional[str] = Header(None),
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> Optional[str]:
    if session_token:
        logger.debug("Found session token in cookie")
        return session_token
    if authorization and authorization.startswith("Session "):
        token = authorization.replace("Session ", "", 1)
        logger.debug("Found session token in Authorization header")
        return token
    if credentials and credentials.credentials:
        logger.debug("Found token in Bearer authorization")
        return credentials.credentials
    if hasattr(request, "query_params") and "token" in request.query_params:
        logger.debug("Found token in query params")
        return request.query_params["token"]
    return None

async def get_current_user(
    request: Request,
    session_token: Optional[str] = Depends(get_session_token)
) -> Optional[User]:
    if not session_token:
        logger.debug("No session token found")
        return None
    
    try:
        user = await auth_manager.get_user_by_session(session_token)
        if user:
            logger.debug(f"Authenticated user: {user.username}")
            request.state.current_user = user
            request.state.user_id = str(user.id)
            request.state.username = user.username
            return user
        else:
            logger.debug("Invalid or expired session token")
            return None
    except Exception as e:
        logger.error(f"Error getting current user: {e}")
        return None

async def require_auth(
    request: Request,
    current_user: Optional[User] = Depends(get_current_user)
) -> User:
    if not current_user:
        logger.warning(f"Unauthenticated access attempt to {request.url.path}")
        if request.url.path.startswith("/api/"):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={
                    "error": "authentication_required", 
                    "message": "You must be logged in to access this resource",
                    "login_url": "/auth/login"
                },
                headers={"WWW-Authenticate": "Bearer"}
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Please log in to continue",
                headers={"Location": "/auth/login"}
            )
    if not current_user.is_active:
        logger.warning(f"Inactive user attempted access: {current_user.username}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account has been deactivated. Please contact support."
        )
    return current_user

async def require_admin(
    request: Request,
    current_user: User = Depends(require_auth)
) -> User:
    if not current_user.is_admin:
        logger.warning(f"Non-admin user attempted admin access: {current_user.username} -> {request.url.path}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": "insufficient_privileges",
                "message": "Admin privileges required to access this resource"
            }
        )
    return current_user

async def require_verified(
    current_user: User = Depends(require_auth)
) -> User:
    if not current_user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": "email_verification_required",
                "message": "Please verify your email address to continue",
                "verification_url": "/auth/verify"
            }
        )
    return current_user

async def get_optional_user(
    current_user: Optional[User] = Depends(get_current_user)
) -> Optional[User]:
    return current_user

async def get_user_or_guest(
    current_user: Optional[User] = Depends(get_current_user)
) -> Union[User, dict]:
    if current_user:
        return current_user
    return {
        "id": "guest",
        "username": "guest", 
        "email": None,
        "full_name": "Guest User",
        "is_active": True,
        "is_verified": False,
        "is_admin": False,
        "is_guest": True
    }

async def check_rate_limit(
    request: Request,
    current_user: Optional[User] = Depends(get_current_user)
) -> bool:
    if current_user:
        client_id = f"user_{current_user.id}"
        max_requests = 1000
    else:
        client_ip = request.client.host if request.client else "unknown"
        client_id = f"ip_{client_ip}"
        max_requests = 100
    logger.debug(f"Rate limit check for {client_id}: allowed")
    return True

async def get_user_context(
    request: Request,
    current_user: Optional[User] = Depends(get_current_user)
) -> dict:
    context = {
        "is_authenticated": current_user is not None,
        "user": current_user.to_dict() if current_user else None,
        "is_admin": current_user.is_admin if current_user else False,
        "is_verified": current_user.is_verified if current_user else False,
        "request_path": str(request.url.path),
        "request_method": request.method
    }
    return context

async def websocket_auth(
    websocket,
    token: Optional[str] = None
) -> Optional[User]:
    if not token:
        token = websocket.query_params.get("token")
    if not token:
        logger.debug("No token provided for WebSocket connection")
        return None
    try:
        user = await auth_manager.get_user_by_session(token)
        if user and user.is_active:
            logger.debug(f"WebSocket authenticated: {user.username}")
            return user
        else:
            logger.debug("Invalid WebSocket token")
            return None
    except Exception as e:
        logger.error(f"WebSocket auth error: {e}")
        return None

class RequireRoles:
    def __init__(self, *roles: str):
        self.roles = roles
    
    def __call__(self, current_user: User = Depends(require_auth)) -> User:
        if "admin" in self.roles and not current_user.is_admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Required roles: {', '.join(self.roles)}"
            )
        return current_user
