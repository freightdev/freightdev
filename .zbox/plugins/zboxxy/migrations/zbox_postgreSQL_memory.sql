-- ZBOX PostgreSQL Memory Schema
-- Advanced memory management with vector embeddings for semantic search

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";  -- For pgvector if available
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- Users table
CREATE TABLE IF NOT EXISTS zbox_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    preferences JSONB DEFAULT '{}',
    memory_enabled BOOLEAN DEFAULT TRUE,
    total_conversations INTEGER DEFAULT 0,
    total_memories INTEGER DEFAULT 0
);

-- User sessions
CREATE TABLE IF NOT EXISTS zbox_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES zbox_users(id) ON DELETE CASCADE,
    session_id VARCHAR(100) UNIQUE NOT NULL,
    api_key VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}'
);

-- Conversations storage
CREATE TABLE IF NOT EXISTS zbox_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES zbox_users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES zbox_sessions(id) ON DELETE CASCADE,
    conversation_id VARCHAR(100) NOT NULL,
    user_message TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    model_used VARCHAR(50) DEFAULT 'primary',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    tokens_used INTEGER DEFAULT 0,
    response_time_ms INTEGER DEFAULT 0,
    user_feedback VARCHAR(20) DEFAULT 'neutral', -- positive, negative, neutral
    metadata JSONB DEFAULT '{}'
);

-- Long-term memory storage
CREATE TABLE IF NOT EXISTS zbox_memories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES zbox_users(id) ON DELETE CASCADE,
    memory_id VARCHAR(100) UNIQUE NOT NULL,
    fact TEXT NOT NULL,
    category VARCHAR(50) DEFAULT 'general',
    importance INTEGER DEFAULT 5 CHECK (importance >= 1 AND importance <= 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    access_count INTEGER DEFAULT 0,
    source_conversation_id UUID REFERENCES zbox_conversations(id),
    verified BOOLEAN DEFAULT FALSE,
    embedding VECTOR(1536), -- OpenAI embedding dimension
    metadata JSONB DEFAULT '{}'
);

-- Context windows (active conversation context)
CREATE TABLE IF NOT EXISTS zbox_context_windows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES zbox_users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES zbox_sessions(id) ON DELETE CASCADE,
    context_data JSONB NOT NULL,
    token_count INTEGER DEFAULT 0,
    max_tokens INTEGER DEFAULT 4096,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User interaction patterns (for learning)
CREATE TABLE IF NOT EXISTS zbox_interaction_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES zbox_users(id) ON DELETE CASCADE,
    pattern_type VARCHAR(50) NOT NULL, -- message_length, time_preference, topic_interest, etc.
    pattern_data JSONB NOT NULL,
    confidence_score DECIMAL(3,2) DEFAULT 0.5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Memory tags for better organization
CREATE TABLE IF NOT EXISTS zbox_memory_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    memory_id UUID REFERENCES zbox_memories(id) ON DELETE CASCADE,
    tag VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(memory_id, tag)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversations_user_timestamp ON zbox_conversations(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_session ON zbox_conversations(session_id);
CREATE INDEX IF NOT EXISTS idx_memories_user_category ON zbox_memories(user_id, category);
CREATE INDEX IF NOT EXISTS idx_memories_importance ON zbox_memories(importance DESC);
CREATE INDEX IF NOT EXISTS idx_memories_access_count ON zbox_memories(access_count DESC);
CREATE INDEX IF NOT EXISTS idx_memories_text_search ON zbox_memories USING GIN (to_tsvector('english', fact));
CREATE INDEX IF NOT EXISTS idx_sessions_user_active ON zbox_sessions(user_id, active);
CREATE INDEX IF NOT EXISTS idx_context_windows_session ON zbox_context_windows(session_id);

-- Full text search index
CREATE INDEX IF NOT EXISTS idx_conversations_text_search 
ON zbox_conversations USING GIN (to_tsvector('english', user_message || ' ' || ai_response));

-- Vector similarity index (if pgvector is available)
-- CREATE INDEX IF NOT EXISTS idx_memories_embedding ON zbox_memories USING ivfflat (embedding vector_cosine_ops);

-- Functions for memory management
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update conversation count
    IF TG_TABLE_NAME = 'zbox_conversations' THEN
        UPDATE zbox_users 
        SET total_conversations = (
            SELECT COUNT(*) FROM zbox_conversations 
            WHERE user_id = NEW.user_id
        ),
        last_active = NOW()
        WHERE id = NEW.user_id;
    END IF;
    
    -- Update memory count
    IF TG_TABLE_NAME = 'zbox_memories' THEN
        UPDATE zbox_users 
        SET total_memories = (
            SELECT COUNT(*) FROM zbox_memories 
            WHERE user_id = NEW.user_id
        )
        WHERE id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_user_conversation_count
    AFTER INSERT ON zbox_conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_user_stats();

CREATE TRIGGER update_user_memory_count
    AFTER INSERT ON zbox_memories
    FOR EACH ROW
    EXECUTE FUNCTION update_user_stats();

-- Function to get relevant memories for a user
CREATE OR REPLACE FUNCTION get_relevant_memories(
    p_user_id UUID,
    p_query TEXT,
    p_category VARCHAR(50) DEFAULT NULL,
    p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    memory_id UUID,
    fact TEXT,
    category VARCHAR(50),
    importance INTEGER,
    similarity_score REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.fact,
        m.category,
        m.importance,
        ts_rank(to_tsvector('english', m.fact), plainto_tsquery('english', p_query)) as similarity
    FROM zbox_memories m
    WHERE m.user_id = p_user_id
    AND (p_category IS NULL OR m.category = p_category)
    AND to_tsvector('english', m.fact) @@ plainto_tsquery('english', p_query)
    ORDER BY similarity DESC, m.importance DESC, m.access_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to store conversation with context
CREATE OR REPLACE FUNCTION store_conversation_with_context(
    p_user_id UUID,
    p_session_id UUID,
    p_user_message TEXT,
    p_ai_response TEXT,
    p_model_used VARCHAR(50) DEFAULT 'primary',
    p_tokens_used INTEGER DEFAULT 0,
    p_response_time_ms INTEGER DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
    conversation_uuid UUID;
    context_data JSONB;
BEGIN
    -- Insert conversation
    INSERT INTO zbox_conversations (
        user_id, session_id, conversation_id, user_message, ai_response, 
        model_used, tokens_used, response_time_ms
    ) VALUES (
        p_user_id, p_session_id, uuid_generate_v4()::text, 
        p_user_message, p_ai_response, p_model_used, p_tokens_used, p_response_time_ms
    ) RETURNING id INTO conversation_uuid;
    
    -- Update context window
    SELECT context_data INTO context_data
    FROM zbox_context_windows 
    WHERE user_id = p_user_id AND session_id = p_session_id;
    
    IF context_data IS NULL THEN
        -- Create new context window
        INSERT INTO zbox_context_windows (user_id, session_id, context_data, token_count)
        VALUES (p_user_id, p_session_id, 
                jsonb_build_array(jsonb_build_object(
                    'user_message', p_user_message,
                    'ai_response', p_ai_response,
                    'timestamp', NOW(),
                    'tokens', p_tokens_used
                )), 
                p_tokens_used);
    ELSE
        -- Update existing context window
        UPDATE zbox_context_windows 
        SET context_data = context_data || jsonb_build_array(jsonb_build_object(
                'user_message', p_user_message,
                'ai_response', p_ai_response,
                'timestamp', NOW(),
                'tokens', p_tokens_used
            )),
            token_count = token_count + p_tokens_used,
            updated_at = NOW()
        WHERE user_id = p_user_id AND session_id = p_session_id;
        
        -- Trim context if too large
        UPDATE zbox_context_windows 
        SET context_data = context_data - 0
        WHERE user_id = p_user_id AND session_id = p_session_id 
        AND token_count > max_tokens;
    END IF;
    
    RETURN conversation_uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup old data
CREATE OR REPLACE FUNCTION cleanup_old_memory_data(
    p_days_old INTEGER DEFAULT 90
)
RETURNS INTEGER AS $$
DECLARE
    rows_deleted INTEGER := 0;
BEGIN
    -- Archive old conversations to separate table (optional)
    -- DELETE FROM zbox_conversations 
    -- WHERE timestamp < NOW() - INTERVAL '%s days', p_days_old
    -- RETURNING 1 INTO rows_deleted;
    
    -- Clean up inactive sessions
    DELETE FROM zbox_sessions 
    WHERE active = FALSE 
    AND last_activity < NOW() - INTERVAL '%s days'
    RETURNING 1;
    
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    
    -- Update memory access patterns (mark rarely accessed memories)
    UPDATE zbox_memories 
    SET metadata = metadata || '{"archived": true}'::jsonb
    WHERE last_accessed < NOW() - INTERVAL '%s days'
    AND access_count < 5;
    
    RETURN rows_deleted;
END;
$ LANGUAGE plpgsql;

-- Views for easy querying
CREATE OR REPLACE VIEW zbox_user_memory_summary AS
SELECT 
    u.username,
    u.total_conversations,
    u.total_memories,
    u.last_active,
    COUNT(DISTINCT s.id) as active_sessions,
    AVG(c.tokens_used) as avg_tokens_per_conversation,
    string_agg(DISTINCT m.category, ', ') as memory_categories
FROM zbox_users u
LEFT JOIN zbox_sessions s ON u.id = s.user_id AND s.active = true
LEFT JOIN zbox_conversations c ON u.id = c.user_id
LEFT JOIN zbox_memories m ON u.id = m.user_id
GROUP BY u.id, u.username, u.total_conversations, u.total_memories, u.last_active;

CREATE OR REPLACE VIEW zbox_recent_activity AS
SELECT 
    u.username,
    'conversation' as activity_type,
    c.user_message as content,
    c.timestamp,
    c.model_used,
    s.session_id
FROM zbox_conversations c
JOIN zbox_users u ON c.user_id = u.id
JOIN zbox_sessions s ON c.session_id = s.id
WHERE c.timestamp > NOW() - INTERVAL '24 hours'
UNION ALL
SELECT 
    u.username,
    'memory' as activity_type,
    m.fact as content,
    m.created_at as timestamp,
    m.category as model_used,
    NULL as session_id
FROM zbox_memories m
JOIN zbox_users u ON m.user_id = u.id
WHERE m.created_at > NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;