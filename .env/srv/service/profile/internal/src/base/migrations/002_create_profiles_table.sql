// internal/infrastructure/database/migrations/002_create_profiles_table.sql
/*
-- +migrate Up
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    avatar TEXT,
    bio TEXT,
    location VARCHAR(100),
    website VARCHAR(255),
    date_of_birth DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_profiles_full_name ON profiles(first_name, last_name);

-- +migrate Down
DROP TABLE IF EXISTS profiles;
*/
