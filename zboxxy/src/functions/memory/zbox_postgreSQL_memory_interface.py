#!/usr/bin/env python3
"""
ZBOX PostgreSQL Memory Interface
Handles all database operations for user memory, conversations, and context
"""

import os
import json
import uuid
import asyncio
import asyncpg
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ZBoxPostgresMemory:
    def __init__(self, database_url: str = None):
        self.database_url = database_url or os.getenv(
            "ZBOX_DATABASE_URL", 
            "postgresql://zbox:zbox_pass@localhost:5432/zbox_memory"
        )
        self.pool = None
        
    async def initialize(self):
        """Initialize database connection pool"""
        try:
            self.pool = await asyncpg.create_pool(
                self.database_url,
                min_size=2,
                max_size=10,
                command_timeout=30
            )
            logger.info("✅ Database connection pool initialized")
            return True
        except Exception as e:
            logger.error(f"❌ Database initialization failed: {e}")
            return False
    
    async def close(self):
        """Close database connections"""
        if self.pool:
            await self.pool.close()
    
    # ============================================================================
    # USER MANAGEMENT
    # ============================================================================
    
    async def create_user(self, username: str, preferences: Dict = None) -> str:
        """Create a new user and return user ID"""
        user_id = str(uuid.uuid4())
        preferences = preferences or {}
        
        async with self.pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO zbox_users (id, username, preferences)
                VALUES ($1, $2, $3)
                ON CONFLICT (username) DO NOTHING
            """, user_id, username, json.dumps(preferences))
            
        logger.info(f"👤 User created/verified: {username}")
        return user_id
    
    async def get_user(self, username: str) -> Optional[Dict]:
        """Get user information"""
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT id, username, created_at, last_active, preferences,
                       total_conversations, total_memories, memory_enabled
                FROM zbox_users WHERE username = $1
            """, username)
            
            if row:
                return dict(row)
        return None
    
    async def create_session(self, username: str, session_id: str, api_key: str) -> str:
        """Create a new user session"""
        user = await self.get_user(username)
        if not user:
            user_id = await self.create_user(username)
        else:
            user_id = user['id']
        
        session_uuid = str(uuid.uuid4())
        
        async with self.pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO zbox_sessions (id, user_id, session_id, api_key)
                VALUES ($1, $2, $3, $4)
            """, session_uuid, user_id, session_id, api_key)
            
        logger.info(f"🔑 Session created: {session_id[:12]}... for {username}")
        return session_uuid
    
    # ============================================================================
    # CONVERSATION MANAGEMENT
    # ============================================================================
    
    async def store_conversation(self, username: str, session_id: str, 
                               user_message: str, ai_response: str,
                               model_used: str = "primary", 
                               tokens_used: int = 0,
                               response_time_ms: int = 0) -> str:
        """Store a conversation turn and update context"""
        
        # Get user and session info
        user = await self.get_user(username)
        if not user:
            return None
            
        async with self.pool.acquire() as conn:
            # Get session UUID
            session_row = await conn.fetchrow("""
                SELECT id FROM zbox_sessions 
                WHERE user_id = $1 AND session_id = $2 AND active = true
            """, user['id'], session_id)
            
            if not session_row:
                logger.warning(f"Session not found: {session_id}")
                return None
            
            # Store conversation using stored procedure
            conversation_id = await conn.fetchval("""
                SELECT store_conversation_with_context($1, $2, $3, $4, $5, $6, $7)
            """, user['id'], session_row['id'], user_message, ai_response, 
                model_used, tokens_used, response_time_ms)
            
        logger.info(f"💬 Conversation stored: {str(conversation_id)[:12]}...")
        return str(conversation_id)
    
    async def get_conversation_context(self, username: str, session_id: str, 
                                    limit: int = 10) -> List[Dict]:
        """Get recent conversation context for a user session"""
        user = await self.get_user(username)
        if not user:
            return []
        
        async with self.pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT c.user_message, c.ai_response, c.timestamp, c.tokens_used
                FROM zbox_conversations c
                JOIN zbox_sessions s ON c.session_id = s.id
                WHERE c.user_id = $1 AND s.session_id = $2
                ORDER BY c.timestamp DESC
                LIMIT $3
            """, user['id'], session_id, limit)
            
        # Return in chronological order (oldest first)
        context = []
        for row in reversed(rows):
            context.append({
                'user_message': row['user_message'],
                'ai_response': row['ai_response'],
                'timestamp': row['timestamp'].isoformat(),
                'tokens': row['tokens_used']
            })
            
        return context
    
    # ============================================================================
    # LONG-TERM MEMORY
    # ============================================================================
    
    async def store_memory(self, username: str, fact: str, category: str = "general",
                         importance: int = 5, source_conversation_id: str = None,
                         tags: List[str] = None) -> str:
        """Store a long-term memory"""
        user = await self.get_user(username)
        if not user:
            return None
            
        memory_id = f"memory_{uuid.uuid4().hex[:16]}"
        memory_uuid = str(uuid.uuid4())
        
        async with self.pool.acquire() as conn:
            async with conn.transaction():
                # Store memory
                await conn.execute("""
                    INSERT INTO zbox_memories 
                    (id, user_id, memory_id, fact, category, importance, source_conversation_id)
                    VALUES ($1, $2, $3, $4, $5, $6, $7)
                """, memory_uuid, user['id'], memory_id, fact, category, importance, 
                    source_conversation_id)
                
                # Add tags if provided
                if tags:
                    for tag in tags:
                        await conn.execute("""
                            INSERT INTO zbox_memory_tags (memory_id, tag)
                            VALUES ($1, $2)
                            ON CONFLICT (memory_id, tag) DO NOTHING
                        """, memory_uuid, tag.lower())
        
        logger.info(f"🧠 Memory stored: {fact[:50]}... (ID: {memory_id})")
        return memory_id
    
    async def recall_memories(self, username: str, query: str, 
                            category: str = None, limit: int = 5) -> List[Dict]:
        """Recall relevant memories for a user"""
        user = await self.get_user(username)
        if not user:
            return []
        
        async with self.pool.acquire() as conn:
            # Update access count for retrieved memories
            memories = await conn.fetch("""
                SELECT * FROM get_relevant_memories($1, $2, $3, $4)
            """, user['id'], query, category, limit)
            
            # Update access counts
            memory_ids = [m['memory_id'] for m in memories]
            if memory_ids:
                await conn.execute("""
                    UPDATE zbox_memories 
                    SET access_count = access_count + 1,
                        last_accessed = NOW()
                    WHERE id = ANY($1)
                """, memory_ids)
        
        result = []
        for memory in memories:
            result.append({
                'memory_id': str(memory['memory_id']),
                'fact': memory['fact'],
                'category': memory['category'],
                'importance': memory['importance'],
                'similarity_score': float(memory['similarity_score'])
            })
        
        return result
    
    async def get_memory_categories(self, username: str) -> List[Dict]:
        """Get memory categories and counts for a user"""
        user = await self.get_user(username)
        if not user:
            return []
        
        async with self.pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT category, COUNT(*) as count, AVG(importance) as avg_importance
                FROM zbox_memories 
                WHERE user_id = $1
                GROUP BY category
                ORDER BY count DESC
            """, user['id'])
        
        return [dict(row) for row in rows]
    
    # ============================================================================
    # USER PREFERENCES & PATTERNS
    # ============================================================================
    
    async def update_preference(self, username: str, key: str, value: Any):
        """Update user preference"""
        user = await self.get_user(username)
        if not user:
            return False
        
        async with self.pool.acquire() as conn:
            await conn.execute("""
                UPDATE zbox_users 
                SET preferences = preferences || $1::jsonb
                WHERE id = $2
            """, json.dumps({key: value}), user['id'])
        
        return True
    
    async def get_preference(self, username: str, key: str, default: Any = None):
        """Get user preference"""
        user = await self.get_user(username)
        if not user:
            return default
        
        preferences = user.get('preferences', {})
        if isinstance(preferences, str):
            preferences = json.loads(preferences)
        
        return preferences.get(key, default)
    
    async def record_interaction_pattern(self, username: str, pattern_type: str, 
                                       pattern_data: Dict, confidence: float = 0.5):
        """Record user interaction pattern for learning"""
        user = await self.get_user(username)
        if not user:
            return
        
        async with self.pool.acquire() as conn:
            await conn.execute("""
                INSERT INTO zbox_interaction_patterns 
                (user_id, pattern_type, pattern_data, confidence_score)
                VALUES ($1, $2, $3, $4)
            """, user['id'], pattern_type, json.dumps(pattern_data), confidence)
    
    # ============================================================================
    # STATISTICS & ANALYTICS
    # ============================================================================
    
    async def get_user_stats(self, username: str) -> Dict:
        """Get comprehensive user statistics"""
        user = await self.get_user(username)
        if not user:
            return {}
        
        async with self.pool.acquire() as conn:
            # Basic stats
            stats = dict(user)
            
            # Recent activity
            recent_conversations = await conn.fetchval("""
                SELECT COUNT(*) FROM zbox_conversations 
                WHERE user_id = $1 AND timestamp > NOW() - INTERVAL '24 hours'
            """, user['id'])
            
            # Memory categories
            categories = await self.get_memory_categories(username)
            
            # Context size
            context_info = await conn.fetchrow("""
                SELECT token_count, jsonb_array_length(context_data) as context_entries
                FROM zbox_context_windows cw
                JOIN zbox_sessions s ON cw.session_id = s.id
                WHERE s.user_id = $1 AND s.active = true
                ORDER BY cw.updated_at DESC
                LIMIT 1
            """, user['id'])
            
            stats.update({
                'recent_conversations_24h': recent_conversations,
                'memory_categories': categories,
                'active_context_tokens': context_info['token_count'] if context_info else 0,
                'active_context_entries': context_info['context_entries'] if context_info else 0
            })
        
        return stats
    
    async def cleanup_old_data(self, days_old: int = 90) -> int:
        """Cleanup old memory data"""
        async with self.pool.acquire() as conn:
            rows_cleaned = await conn.fetchval("""
                SELECT cleanup_old_memory_data($1)
            """, days_old)
        
        logger.info(f"🧹 Cleaned up {rows_cleaned} old records")
        return rows_cleaned
    
    # ============================================================================
    # CONTEXT MANAGEMENT
    # ============================================================================
    
    async def get_enhanced_context(self, username: str, session_id: str, 
                                 current_message: str, context_limit: int = 5,
                                 memory_limit: int = 3) -> Dict:
        """Get enhanced context including conversation history and relevant memories"""
        
        # Get conversation context
        conversation_context = await self.get_conversation_context(
            username, session_id, context_limit
        )
        
        # Get relevant memories
        relevant_memories = await self.recall_memories(
            username, current_message, limit=memory_limit
        )
        
        # Build enhanced context
        context = {
            'conversation_history': conversation_context,
            'relevant_memories': relevant_memories,
            'user_stats': await self.get_user_stats(username),
            'timestamp': datetime.now().isoformat()
        }
        
        return context

# Global instance
zbox_db = ZBoxPostgresMemory()

# ============================================================================
# CLI Functions for ZSH Integration
# ============================================================================

async def cli_store_conversation(username: str, session_id: str, user_msg: str, 
                               ai_response: str, model: str = "primary") -> str:
    """CLI function to store conversation"""
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    return await zbox_db.store_conversation(
        username, session_id, user_msg, ai_response, model
    )

async def cli_recall_memories(username: str, query: str, limit: int = 5) -> List[Dict]:
    """CLI function to recall memories"""
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    return await zbox_db.recall_memories(username, query, limit=limit)

async def cli_get_context(username: str, session_id: str, 
                        current_message: str) -> Dict:
    """CLI function to get enhanced context"""
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    return await zbox_db.get_enhanced_context(username, session_id, current_message)

async def cli_user_stats(username: str) -> Dict:
    """CLI function to get user stats"""
    if not zbox_db.pool:
        await zbox_db.initialize()
    
    return await zbox_db.get_user_stats(username)

# Command line interface
if __name__ == "__main__":
    import sys
    
    async def main():
        if len(sys.argv) < 2:
            print("Usage: zbox_postgres_interface.py <command> [args...]")
            return
        
        await zbox_db.initialize()
        
        command = sys.argv[1]
        
        if command == "create_user" and len(sys.argv) >= 3:
            username = sys.argv[2]
            user_id = await zbox_db.create_user(username)
            print(f"Created user: {username} (ID: {user_id})")
            
        elif command == "get_stats" and len(sys.argv) >= 3:
            username = sys.argv[2]
            stats = await cli_user_stats(username)
            print(json.dumps(stats, indent=2, default=str))
            
        elif command == "recall" and len(sys.argv) >= 4:
            username = sys.argv[2]
            query = sys.argv[3]
            memories = await cli_recall_memories(username, query)
            for memory in memories:
                print(f"[{memory['category']}] {memory['fact']} (score: {memory['similarity_score']:.2f})")
                
        elif command == "cleanup":
            days = int(sys.argv[2]) if len(sys.argv) >= 3 else 90
            cleaned = await zbox_db.cleanup_old_data(days)
            print(f"Cleaned up {cleaned} old records")
            
        else:
            print(f"Unknown command: {command}")
        
        await zbox_db.close()
    
    asyncio.run(main())