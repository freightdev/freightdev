## Database Migrations Explained 🗄️

Migrations are **versioned database schema changes** that let you evolve your database structure over time while keeping data intact.

---

### **🎯 What Are Migrations?**

Think of migrations as **"database recipes"** that:
- Create tables, columns, indexes
- Modify existing structure  
- Transform data during changes
- Can be applied incrementally
- Can be rolled back if needed

**Example Flow:**
```
Migration 001: Create users table
Migration 002: Add email column to users
Migration 003: Create conversations table
Migration 004: Add foreign key relationship
```

---

### **📁 Your Migration Files Structure**

```
migrations/
├── 001_initial.sql           # Create core tables
├── 002_conversations.sql     # Add conversation system
├── 003_embeddings.sql        # Add embeddings support
├── 004_agents.sql            # Add agent-specific fields
├── 005_git_integration.sql   # Add git/file tracking
└── 006_performance.sql       # Add indexes and optimizations
```

---

### **📋 Migration File Contents**

**File 1: `migrations/001_initial.sql`**

```sql
-- Migration 001: Initial database structure
-- Created: 2025-01-01
-- Description: Core tables for AI Assistant

-- Enable UUID extension for PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (basic user management)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    preferences JSONB DEFAULT '{}'::jsonb
);

-- System settings table
CREATE TABLE IF NOT EXISTS system_settings (
    key VARCHAR(255) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Model configurations table
CREATE TABLE IF NOT EXISTS model_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    model_path TEXT NOT NULL,
    config JSONB NOT NULL,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_model_configs_default ON model_configs(is_default);

-- Insert default system settings
INSERT INTO system_settings (key, value, description) VALUES
('app_version', '"1.0.0"', 'Application version'),
('default_temperature', '0.7', 'Default model temperature'),
('max_context_length', '4096', 'Maximum context length'),
('enable_embeddings', 'true', 'Enable embeddings system')
ON CONFLICT (key) DO NOTHING;

-- Create default user
INSERT INTO users (id, username, email) VALUES
(uuid_generate_v4(), 'admin', 'admin@localhost')
ON CONFLICT (username) DO NOTHING;
```

**File 2: `migrations/002_conversations.sql`**

```sql
-- Migration 002: Conversation system
-- Created: 2025-01-01
-- Description: Add conversation and message tables

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500),
    agent_type VARCHAR(100) DEFAULT 'chat',
    context_length INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    token_count INTEGER,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Generation metadata
    model_name VARCHAR(255),
    generation_time FLOAT,
    temperature FLOAT,
    generation_config JSONB DEFAULT '{}'::jsonb
);

-- Conversation statistics table
CREATE TABLE IF NOT EXISTS conversation_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    total_messages INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    avg_response_time FLOAT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_agent_type ON conversations(agent_type);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_role ON messages(role);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_messages_model_name ON messages(model_name);

CREATE INDEX IF NOT EXISTS idx_conversation_stats_conversation_id ON conversation_stats(conversation_id);

-- Function to update conversation updated_at timestamp
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations 
    SET updated_at = NOW() 
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update conversation timestamp when messages are added
CREATE TRIGGER trigger_update_conversation_timestamp
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_timestamp();

-- Function to update conversation stats
CREATE OR REPLACE FUNCTION update_conversation_stats()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO conversation_stats (conversation_id, total_messages, total_tokens)
    SELECT 
        NEW.conversation_id,
        COUNT(*),
        SUM(COALESCE(token_count, 0))
    FROM messages 
    WHERE conversation_id = NEW.conversation_id
    ON CONFLICT (conversation_id) DO UPDATE SET
        total_messages = EXCLUDED.total_messages,
        total_tokens = EXCLUDED.total_tokens,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update stats when messages change
CREATE TRIGGER trigger_update_conversation_stats
    AFTER INSERT OR UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_stats();
```

**File 3: `migrations/003_embeddings.sql`**

```sql
-- Migration 003: Embeddings and vector search
-- Created: 2025-01-01
-- Description: Add embeddings support for semantic search

-- Enable vector extension if available (for pgvector)
-- CREATE EXTENSION IF NOT EXISTS vector;

-- Conversation embeddings table
CREATE TABLE IF NOT EXISTS conversation_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    content_hash VARCHAR(64) NOT NULL,
    embedding_vector FLOAT[] NOT NULL, -- Store as array for now
    chunk_text TEXT NOT NULL,
    chunk_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Metadata for the embedding
    source_type VARCHAR(50) DEFAULT 'message', -- message, file, etc.
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Knowledge base table (for uploaded documents/files)
CREATE TABLE IF NOT EXISTS knowledge_base (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    source VARCHAR(500), -- file path, URL, etc.
    content_type VARCHAR(100) DEFAULT 'text',
    file_hash VARCHAR(64),
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    embedding_vector FLOAT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- File metadata
    file_size INTEGER,
    file_extension VARCHAR(50),
    language VARCHAR(50)
);

-- Embedding models table (track which embedding model was used)
CREATE TABLE IF NOT EXISTS embedding_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    model_path TEXT,
    dimension INTEGER NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for embeddings
CREATE INDEX IF NOT EXISTS idx_conversation_embeddings_conversation_id ON conversation_embeddings(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_embeddings_message_id ON conversation_embeddings(message_id);
CREATE INDEX IF NOT EXISTS idx_conversation_embeddings_content_hash ON conversation_embeddings(content_hash);
CREATE INDEX IF NOT EXISTS idx_conversation_embeddings_source_type ON conversation_embeddings(source_type);

CREATE INDEX IF NOT EXISTS idx_knowledge_base_content_type ON knowledge_base(content_type);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_tags ON knowledge_base USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_file_hash ON knowledge_base(file_hash);
CREATE INDEX IF NOT EXISTS idx_knowledge_base_language ON knowledge_base(language);

CREATE INDEX IF NOT EXISTS idx_embedding_models_active ON embedding_models(is_active);

-- Full text search indexes
CREATE INDEX IF NOT EXISTS idx_knowledge_base_content_fts ON knowledge_base USING gin(to_tsvector('english', content));
CREATE INDEX IF NOT EXISTS idx_conversation_embeddings_chunk_fts ON conversation_embeddings USING gin(to_tsvector('english', chunk_text));

-- Insert default embedding model
INSERT INTO embedding_models (name, dimension, description) VALUES
('all-MiniLM-L6-v2', 384, 'Default sentence transformer model')
ON CONFLICT (name) DO NOTHING;

-- Function to generate content hash
CREATE OR REPLACE FUNCTION generate_content_hash(content TEXT)
RETURNS VARCHAR(64) AS $$
BEGIN
    RETURN encode(digest(content, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql;

-- Function to update knowledge base updated_at
CREATE OR REPLACE FUNCTION update_knowledge_base_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for knowledge base updates
CREATE TRIGGER trigger_update_knowledge_base_timestamp
    BEFORE UPDATE ON knowledge_base
    FOR EACH ROW
    EXECUTE FUNCTION update_knowledge_base_timestamp();
```

---

### **⚡ Quick Commands for Migrations**

**Run migrations:**
```bash
# In your Python environment
python -c "
import asyncio
from backend.utils.migrations import MigrationRunner
from backend.app.config import settings

async def main():
    runner = MigrationRunner(settings.postgres_url)
    await runner.run_migrations()

asyncio.run(main())
"
```

**Create new migration:**
```bash
# Create new migration file
touch migrations/004_$(date +%Y%m%d)_your_feature_name.sql
```

**Check migration status:**
```sql
-- Connect to your database and run:
SELECT version, filename, applied_at 
FROM schema_migrations 
ORDER BY version;
```

---

### **🎯 Why Use Migrations?**

✅ **Version Control** - Track database changes like code  
✅ **Team Sync** - Everyone gets the same database structure  
✅ **Safe Updates** - Apply changes incrementally  
✅ **Rollback Capability** - Undo changes if needed  
✅ **Production Safety** - Test schema changes before deploying  

Your AI Assistant will automatically run migrations on startup, ensuring your database is always up to date! 🚀