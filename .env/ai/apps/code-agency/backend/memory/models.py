import uuid
import bcrypt
import secrets
from datetime import datetime, timedelta

from sqlalchemy import Column, String, DateTime, Boolean, Text, Integer, ForeignKey, JSON, Float, ARRAY
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    full_name = Column(String(255))
    password_hash = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = Column(DateTime)
    avatar_url = Column(String(500))
    timezone = Column(String(50), default="UTC")
    preferences = Column(Text)

    sessions = relationship("UserSession", back_populates="user", cascade="all, delete-orphan")
    conversations = relationship("Conversation", back_populates="user", cascade="all, delete-orphan")

    def set_password(self, password: str):
        salt = bcrypt.gensalt()
        self.password_hash = bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")

    def check_password(self, password: str) -> bool:
        return bcrypt.checkpw(password.encode("utf-8"), self.password_hash.encode("utf-8"))

    def to_dict(self):
        return {
            "id": str(self.id),
            "username": self.username,
            "email": self.email,
            "full_name": self.full_name,
            "is_active": self.is_active,
            "is_verified": self.is_verified,
            "is_admin": self.is_admin,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_login": self.last_login.isoformat() if self.last_login else None,
            "avatar_url": self.avatar_url,
            "timezone": self.timezone
        }


class UserSession(Base):
    __tablename__ = "user_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    session_token = Column(String(255), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)
    last_used = Column(DateTime, default=datetime.utcnow)
    user_agent = Column(Text)
    ip_address = Column(String(45))
    device_name = Column(String(255))
    is_active = Column(Boolean, default=True)

    user = relationship("User", back_populates="sessions")

    @classmethod
    def create_session(cls, user_id: uuid.UUID, expires_in_days: int = 30) -> 'UserSession':
        session_token = secrets.token_urlsafe(32)
        expires_at = datetime.utcnow() + timedelta(days=expires_in_days)
        return cls(
            user_id=user_id,
            session_token=session_token,
            expires_at=expires_at
        )

    def is_expired(self) -> bool:
        return datetime.utcnow() > self.expires_at

    def refresh_last_used(self):
        self.last_used = datetime.utcnow()


class UserInvitation(Base):
    __tablename__ = "user_invitations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), nullable=False)
    invited_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    invitation_token = Column(String(255), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)
    used_at = Column(DateTime)
    is_used = Column(Boolean, default=False)

    @classmethod
    def create_invitation(cls, email: str, invited_by_id: uuid.UUID) -> 'UserInvitation':
        token = secrets.token_urlsafe(32)
        expires_at = datetime.utcnow() + timedelta(days=7)
        return cls(
            email=email,
            invited_by=invited_by_id,
            invitation_token=token,
            expires_at=expires_at
        )


class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String(500))
    agent_type = Column(String(100), default="chat")
    context_length = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    metadata_json = Column(JSON)

    user = relationship("User", back_populates="conversations")
    messages = relationship(
        "Message",
        back_populates="conversation",
        cascade="all, delete-orphan",
        passive_deletes=True
    )
    embeddings = relationship(
        "ConversationEmbedding",
        back_populates="conversation",
        cascade="all, delete-orphan",
        passive_deletes=True
    )


class Message(Base):
    __tablename__ = "messages"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    conversation_id = Column(UUID(as_uuid=True), ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    role = Column(String(50), nullable=False)
    content = Column(Text, nullable=False)
    token_count = Column(Integer, default=0)
    timestamp = Column(DateTime, default=datetime.utcnow)
    model_name = Column(String(255))
    generation_time = Column(Float)
    temperature = Column(Float)

    conversation = relationship("Conversation", back_populates="messages")


class ConversationEmbedding(Base):
    __tablename__ = "conversation_embeddings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    conversation_id = Column(UUID(as_uuid=True), ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    content_hash = Column(String(64), nullable=False)
    embedding = Column(ARRAY(Float), nullable=False)
    chunk_index = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    conversation = relationship("Conversation", back_populates="embeddings")


class KnowledgeBase(Base):
    __tablename__ = "knowledge_base"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(500), nullable=False)
    content = Column(Text, nullable=False)
    source = Column(String(500))
    content_type = Column(String(100))
    tags = Column(ARRAY(String))
    embedding = Column(ARRAY(Float))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
