"""
JWT Authentication Handler
Secure multi-user authentication with role-based access control
"""

from datetime import datetime, timedelta
from typing import Optional
import jwt
from passlib.context import CryptContext
from pydantic import BaseModel

# Security configuration
SECRET_KEY = "CHANGE_THIS_IN_PRODUCTION_use_secrets_manager"  # TODO: Move to env
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours
REFRESH_TOKEN_EXPIRE_DAYS = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class User(BaseModel):
    username: str
    email: str
    full_name: Optional[str] = None
    disabled: bool = False
    role: str = "user"  # user, admin, superadmin


class UserInDB(User):
    hashed_password: str


class TokenData(BaseModel):
    username: Optional[str] = None
    role: Optional[str] = None


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Hash a password"""
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create JWT access token"""
    to_encode = data.copy()

    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: dict):
    """Create JWT refresh token"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def decode_token(token: str) -> Optional[dict]:
    """Decode and verify JWT token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.JWTError:
        return None


# In-memory user database (TODO: Replace with actual database)
fake_users_db = {
    "admin": UserInDB(
        username="admin",
        email="admin@agency.local",
        full_name="Agency Administrator",
        disabled=False,
        role="superadmin",
        hashed_password=get_password_hash("admin123")  # CHANGE THIS!
    ),
    "demo": UserInDB(
        username="demo",
        email="demo@agency.local",
        full_name="Demo User",
        disabled=False,
        role="user",
        hashed_password=get_password_hash("demo123")
    )
}


def authenticate_user(username: str, password: str) -> Optional[UserInDB]:
    """Authenticate a user"""
    user = fake_users_db.get(username)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user


def get_user(username: str) -> Optional[UserInDB]:
    """Get user by username"""
    return fake_users_db.get(username)


def create_user(username: str, email: str, password: str, full_name: str = "", role: str = "user") -> UserInDB:
    """Create a new user"""
    if username in fake_users_db:
        raise ValueError("User already exists")

    user = UserInDB(
        username=username,
        email=email,
        full_name=full_name,
        disabled=False,
        role=role,
        hashed_password=get_password_hash(password)
    )

    fake_users_db[username] = user
    return user
