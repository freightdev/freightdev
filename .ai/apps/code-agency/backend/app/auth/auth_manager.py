import logging
from datetime import datetime
from typing import Optional, Dict, Any

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from ...memory.models import User, UserSession, UserInvitation
from ...memory.database import db_manager

logger = logging.getLogger(__name__)

class AuthManager:
    def __init__(self):
        self.session_duration_days = 30
    
    async def create_user(self, username: str, email: str, password: str, 
                        full_name: str = None, is_admin: bool = False) -> Optional[User]:
        session = await db_manager.get_postgres_session()
        
        try:
            existing = await session.execute(
                select(User).where((User.username == username) | (User.email == email))
            )
            if existing.scalar_one_or_none():
                return None
            
            user = User(
                username=username,
                email=email,
                full_name=full_name,
                is_admin=is_admin,
                is_verified=True
            )
            user.set_password(password)
            
            session.add(user)
            await session.commit()
            await session.refresh(user)
            
            logger.info(f"Created user: {username}")
            return user
            
        except Exception as e:
            await session.rollback()
            logger.error(f"Error creating user: {e}")
            return None
        finally:
            await session.close()
    
    async def authenticate_user(self, username: str, password: str) -> Optional[User]:
        session = await db_manager.get_postgres_session()
        
        try:
            result = await session.execute(
                select(User).where(
                    (User.username == username) | (User.email == username)
                ).where(User.is_active == True)
            )
            user = result.scalar_one_or_none()
            
            if user and user.check_password(password):
                await session.execute(
                    update(User).where(User.id == user.id)
                    .values(last_login=datetime.utcnow())
                )
                await session.commit()
                
                logger.info(f"User authenticated: {username}")
                return user
            
            return None
            
        except Exception as e:
            logger.error(f"Authentication error: {e}")
            return None
        finally:
            await session.close()
    
    async def create_session(self, user_id: str, user_agent: str = None, 
                           ip_address: str = None) -> Optional[UserSession]:
        session = await db_manager.get_postgres_session()
        
        try:
            user_session = UserSession.create_session(user_id, self.session_duration_days)
            user_session.user_agent = user_agent
            user_session.ip_address = ip_address
            
            session.add(user_session)
            await session.commit()
            await session.refresh(user_session)
            
            return user_session
            
        except Exception as e:
            await session.rollback()
            logger.error(f"Error creating session: {e}")
            return None
        finally:
            await session.close()
    
    async def get_user_by_session(self, session_token: str) -> Optional[User]:
        session = await db_manager.get_postgres_session()
        
        try:
            result = await session.execute(
                select(UserSession).where(
                    UserSession.session_token == session_token
                ).where(UserSession.is_active == True)
            )
            user_session = result.scalar_one_or_none()
            
            if user_session and not user_session.is_expired():
                user_session.refresh_last_used()
                await session.commit()
                
                user_result = await session.execute(
                    select(User).where(User.id == user_session.user_id)
                    .where(User.is_active == True)
                )
                return user_result.scalar_one_or_none()
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting user by session: {e}")
            return None
        finally:
            await session.close()
    
    async def invalidate_session(self, session_token: str) -> bool:
        session = await db_manager.get_postgres_session()
        
        try:
            await session.execute(
                update(UserSession).where(UserSession.session_token == session_token)
                .values(is_active=False)
            )
            await session.commit()
            return True
            
        except Exception as e:
            logger.error(f"Error invalidating session: {e}")
            return False
        finally:
            await session.close()
    
    async def get_all_users(self) -> list[User]:
        session = await db_manager.get_postgres_session()
        
        try:
            result = await session.execute(select(User).order_by(User.created_at))
            return list(result.scalars().all())
        except Exception as e:
            logger.error(f"Error getting users: {e}")
            return []
        finally:
            await session.close()
    
    async def create_invitation(self, email: str, invited_by_id: str) -> Optional[UserInvitation]:
        session = await db_manager.get_postgres_session()
        
        try:
            invitation = UserInvitation.create_invitation(email, invited_by_id)
            session.add(invitation)
            await session.commit()
            await session.refresh(invitation)
            
            return invitation
            
        except Exception as e:
            await session.rollback()
            logger.error(f"Error creating invitation: {e}")
            return None
        finally:
            await session.close()

auth_manager = AuthManager()
