import uuid
import logging
from typing import List, Dict, Optional, Tuple
from datetime import datetime

from sqlalchemy import select, desc, and_
from sqlalchemy.ext.asyncio import AsyncSession

from .database import db_manager
from .models import Conversation, Message, ConversationEmbedding, KnowledgeBase
from .embeddings import embedding_manager

logger = logging.getLogger(__name__)


class InMemoryStorage:
    """Fallback in-memory storage when database is unavailable"""

    def __init__(self):
        self.conversations: Dict[str, Dict] = {}
        self.messages: Dict[str, List[Dict]] = {}

    async def create_conversation(self, user_id: str, title: str = None, agent_type: str = "chat") -> str:
        """Create a new conversation in memory"""
        conv_id = str(uuid.uuid4())
        self.conversations[conv_id] = {
            'id': conv_id,
            'user_id': user_id,
            'title': title or f"Conversation {datetime.utcnow().strftime('%Y-%m-%d %H:%M')}",
            'agent_type': agent_type,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'context_length': 0,
            'is_active': True
        }
        self.messages[conv_id] = []
        logger.info(f"Created in-memory conversation {conv_id}")
        return conv_id

    async def save_message(self, conversation_id: str, role: str, content: str,
                          model_name: str = None, generation_time: float = None,
                          temperature: float = None) -> str:
        """Save a message to memory"""
        msg_id = str(uuid.uuid4())
        message = {
            'id': msg_id,
            'conversation_id': conversation_id,
            'role': role,
            'content': content,
            'token_count': int(len(content.split()) * 1.3),
            'model_name': model_name,
            'generation_time': generation_time,
            'temperature': temperature,
            'timestamp': datetime.utcnow()
        }

        if conversation_id not in self.messages:
            self.messages[conversation_id] = []

        self.messages[conversation_id].append(message)

        # Update conversation stats
        if conversation_id in self.conversations:
            total_tokens = sum(msg['token_count'] for msg in self.messages[conversation_id])
            self.conversations[conversation_id]['context_length'] = total_tokens
            self.conversations[conversation_id]['updated_at'] = datetime.utcnow()

        logger.debug(f"Saved in-memory message {msg_id}")
        return msg_id

    async def get_conversation_messages(self, conversation_id: str, limit: int = 50) -> List[Dict]:
        """Get messages from memory"""
        messages = self.messages.get(conversation_id, [])
        return [
            {
                'id': msg['id'],
                'role': msg['role'],
                'content': msg['content'],
                'timestamp': msg['timestamp'].isoformat(),
                'token_count': msg['token_count'],
                'model_name': msg['model_name'],
                'generation_time': msg['generation_time']
            }
            for msg in messages[-limit:]
        ]

    async def get_user_conversations(self, user_id: str, limit: int = 20) -> List[Dict]:
        """Get user's conversations from memory"""
        user_convs = [
            {
                'id': conv['id'],
                'title': conv['title'],
                'agent_type': conv['agent_type'],
                'context_length': conv['context_length'],
                'is_active': conv['is_active'],
                'created_at': conv['created_at'].isoformat(),
                'updated_at': conv['updated_at'].isoformat()
            }
            for conv in self.conversations.values()
            if conv['user_id'] == user_id
        ]
        # Sort by updated_at descending
        user_convs.sort(key=lambda x: x['updated_at'], reverse=True)
        return user_convs[:limit]


class ConversationStorage:
    def __init__(self):
        self.current_session: Optional[AsyncSession] = None
        self.fallback = InMemoryStorage()
        self.use_database = True  # Try database first, fall back to memory if needed

    async def create_conversation(self, user_id: str, title: str = None, agent_type: str = "chat") -> str:
        """Create a new conversation"""
        # Try in-memory first if database previously failed
        if not self.use_database:
            return await self.fallback.create_conversation(user_id, title, agent_type)

        try:
            session = await db_manager.get_postgres_session()

            conversation = Conversation(
                id=uuid.uuid4(),
                user_id=user_id,
                title=title or f"Conversation {datetime.utcnow().strftime('%Y-%m-%d %H:%M')}",
                agent_type=agent_type,
                created_at=datetime.utcnow()
            )

            session.add(conversation)
            await session.commit()
            await session.refresh(conversation)

            logger.info(f"Created conversation {conversation.id} for user {user_id}")
            await session.close()
            return str(conversation.id)

        except Exception as e:
            logger.warning(f"Database unavailable, using in-memory storage: {e}")
            self.use_database = False
            return await self.fallback.create_conversation(user_id, title, agent_type)
    
    
    async def save_message(self, conversation_id: str, role: str, content: str,
                            model_name: str = None, generation_time: float = None,
                            temperature: float = None) -> str:
        """Save a message to the conversation"""
        # Use in-memory if database is unavailable
        if not self.use_database:
            return await self.fallback.save_message(conversation_id, role, content, model_name, generation_time, temperature)

        try:
            session = await db_manager.get_postgres_session()

            # Rough token count estimation
            token_count = int(len(content.split()) * 1.3)

            message = Message(
                id=uuid.uuid4(),
                conversation_id=uuid.UUID(conversation_id),
                role=role,
                content=content,
                token_count=token_count,
                model_name=model_name,
                generation_time=generation_time,
                temperature=temperature,
                timestamp=datetime.utcnow()
            )

            session.add(message)
            await session.commit()
            await session.refresh(message)

            # Update conversation context length
            await self._update_conversation_stats(session, conversation_id)

            # Generate embeddings for the message asynchronously
            await self._generate_message_embedding(str(message.id), content, conversation_id, role)

            logger.debug(f"Saved message {message.id} to conversation {conversation_id}")
            await session.close()
            return str(message.id)

        except Exception as e:
            logger.warning(f"Database unavailable, using in-memory storage: {e}")
            self.use_database = False
            return await self.fallback.save_message(conversation_id, role, content, model_name, generation_time, temperature)
    
    async def get_conversation_messages(self, conversation_id: str, limit: int = 50) -> List[Dict]:
        """Get messages from a conversation"""
        # Use in-memory if database is unavailable
        if not self.use_database:
            return await self.fallback.get_conversation_messages(conversation_id, limit)

        try:
            session = await db_manager.get_postgres_session()

            stmt = select(Message).where(
                Message.conversation_id == uuid.UUID(conversation_id)
            ).order_by(Message.timestamp).limit(limit)

            result = await session.execute(stmt)
            messages = result.scalars().all()

            await session.close()
            return [
                {
                    'id': str(msg.id),
                    'role': msg.role,
                    'content': msg.content,
                    'timestamp': msg.timestamp.isoformat(),
                    'token_count': msg.token_count,
                    'model_name': msg.model_name,
                    'generation_time': msg.generation_time
                }
                for msg in messages
            ]

        except Exception as e:
            logger.warning(f"Database unavailable, using in-memory storage: {e}")
            self.use_database = False
            return await self.fallback.get_conversation_messages(conversation_id, limit)

    async def get_user_conversations(self, user_id: str, limit: int = 20) -> List[Dict]:
        """Get user's conversations"""
        # Use in-memory if database is unavailable
        if not self.use_database:
            return await self.fallback.get_user_conversations(user_id, limit)

        try:
            session = await db_manager.get_postgres_session()

            stmt = select(Conversation).where(
                Conversation.user_id == user_id
            ).order_by(desc(Conversation.updated_at)).limit(limit)

            result = await session.execute(stmt)
            conversations = result.scalars().all()

            await session.close()
            return [
                {
                    'id': str(conv.id),
                    'title': conv.title,
                    'agent_type': conv.agent_type,
                    'context_length': conv.context_length,
                    'is_active': conv.is_active,
                    'created_at': conv.created_at.isoformat(),
                    'updated_at': conv.updated_at.isoformat()
                }
                for conv in conversations
            ]

        except Exception as e:
            logger.warning(f"Database unavailable, using in-memory storage: {e}")
            self.use_database = False
            return await self.fallback.get_user_conversations(user_id, limit)
    
    async def search_conversations(self, user_id: str, query: str, limit: int = 10) -> List[Dict]:
        """Search conversations using embeddings"""
        # Use embedding manager to find similar content
        similar_results = embedding_manager.search_similar(query, k=limit * 2)
        
        # Filter results by user and return conversation info
        conversation_ids = set()
        results = []
        
        for result in similar_results:
            conv_id = result['metadata'].get('conversation_id')
            if conv_id and conv_id not in conversation_ids:
                conversation_ids.add(conv_id)
                results.append({
                    'conversation_id': conv_id,
                    'similarity': result['similarity'],
                    'snippet': result['text'][:200] + "..." if len(result['text']) > 200 else result['text'],
                    'timestamp': result['metadata'].get('timestamp')
                })
        
        return results[:limit]
    
    async def _update_conversation_stats(self, session: AsyncSession, conversation_id: str):
        """Update conversation statistics"""
        try:
            # Count total tokens in conversation
            stmt = select(Message).where(Message.conversation_id == uuid.UUID(conversation_id))
            result = await session.execute(stmt)
            messages = result.scalars().all()
            
            total_tokens = sum(msg.token_count or 0 for msg in messages)
            
            # Update conversation
            conv_stmt = select(Conversation).where(Conversation.id == uuid.UUID(conversation_id))
            conv_result = await session.execute(conv_stmt)
            conversation = conv_result.scalar_one()
            
            conversation.context_length = total_tokens
            conversation.updated_at = datetime.utcnow()
            
            await session.commit()
            
        except Exception as e:
            logger.error(f"Failed to update conversation stats: {e}")
    
    async def _generate_message_embedding(self, message_id: str, content: str, 
                                        conversation_id: str, role: str):
        """Generate and store embedding for a message"""
        try:
            # Generate embedding
            embeddings = embedding_manager.encode_text([content])
            
            if len(embeddings) > 0:
                # Store embedding with metadata
                metadata = [{
                    'message_id': message_id,
                    'conversation_id': conversation_id,
                    'role': role,
                    'timestamp': datetime.utcnow().isoformat(),
                    'token_count': int(len(content.split()) * 1.3)
                }]
                
                embedding_manager.add_embeddings([content], metadata)
                
        except Exception as e:
            logger.error(f"Failed to generate message embedding: {e}")

# Global conversation storage instance
conversation_storage = ConversationStorage()