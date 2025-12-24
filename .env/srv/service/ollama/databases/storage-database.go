// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = database/storage-database.go

package database

import (
	// stdlib
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"strings"
	"sync"
	"time"

	// third-party

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/s3/manager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/marcboeker/go-duckdb"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog/log"
	_ "modernc.org/sqlite"

	// internal
	"ocs/managers"
)

// StoreDatabase manages storage for context, embeddings, state, and user settings
type StoreDatabase struct {
	sqliteDB       *sql.DB
	redisClient    *redis.Client
	duckDBConn     *duckdb.Connector
	duckDB         *sql.DB
	s3Client       *s3.Client
	s3Uploader     *manager.Uploader
	rocksDB        *rocksdb.DB
	configManager  *managers.ConfigManager
	sessionManager *managers.SessionManager
	memoryManager  *managers.MemoryManager
	mutex          sync.RWMutex
}

// NewStoreDatabase initializes storage with SQLite, Redis, DuckDB, RocksDB, and S3
func NewStoreDatabase(
	ctx context.Context,
	configManager *managers.ConfigManager,
	sessionManager *managers.SessionManager,
	memoryManager *managers.MemoryManager,
) (*StoreDatabase, error) {
	// Initialize SQLite
	sqliteDB, err := sql.Open("sqlite", "./ocs_store.db")
	if err != nil {
		return nil, fmt.Errorf("failed to open SQLite database: %v", err)
	}
	if err := initializeSQLiteSchema(sqliteDB); err != nil {
		return nil, fmt.Errorf("failed to initialize SQLite schema: %v", err)
	}

	// Initialize Redis
	redisClient := redis.NewClient(&redis.Options{
		Addr:     configManager.GetConfig("redis_addr", "localhost:6379"),
		Password: configManager.GetConfig("redis_password", ""),
		DB:       0,
	})
	if _, err := redisClient.Ping(ctx).Result(); err != nil {
		return nil, fmt.Errorf("failed to connect to Redis: %v", err)
	}

	// Initialize DuckDB
	duckDBConn, err := duckdb.NewConnector("", nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create DuckDB connector: %v", err)
	}
	duckDB, err := sql.OpenDB(duckDBConn)
	if err != nil {
		return nil, fmt.Errorf("failed to open DuckDB: %v", err)
	}
	if err := initializeDuckDBSchema(duckDB); err != nil {
		return nil, fmt.Errorf("failed to initialize DuckDB schema: %v", err)
	}

	// Initialize RocksDB
	rocksDBOptions := rocksdb.NewDefaultOptions()
	rocksDBOptions.SetCreateIfMissing(true)
	rocksDB, err := rocksdb.OpenDB("./ocs_rocksdb", rocksDBOptions)
	if err != nil {
		return nil, fmt.Errorf("failed to open RocksDB: %v", err)
	}

	// Initialize S3
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %v", err)
	}
	s3Client := s3.NewFromConfig(cfg)
	s3Uploader := manager.NewUploader(s3Client)

	return &StoreDatabase{
		sqliteDB:       sqliteDB,
		redisClient:    redisClient,
		duckDBConn:     duckDBConn,
		duckDB:         duckDB,
		rocksDB:        rocksDB,
		s3Client:       s3Client,
		s3Uploader:     s3Uploader,
		configManager:  configManager,
		sessionManager: sessionManager,
		memoryManager:  memoryManager,
	}, nil
}

// initializeSQLiteSchema sets up SQLite tables for users and settings
func initializeSQLiteSchema(db *sql.DB) error {
	_, err := db.Exec(`
        CREATE TABLE IF NOT EXISTS users (
            user_id TEXT PRIMARY KEY,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            metadata JSON
        );
        CREATE TABLE IF NOT EXISTS user_settings (
            user_id TEXT PRIMARY KEY,
            settings JSON,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(user_id)
        );
        CREATE TABLE IF NOT EXISTS contexts (
            session_id TEXT PRIMARY KEY,
            context_data JSON,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    `)
	return err
}

// initializeDuckDBSchema sets up DuckDB tables for embeddings and analytics
func initializeDuckDBSchema(db *sql.DB) error {
	_, err := db.Exec(`
        CREATE TABLE IF NOT EXISTS embeddings (
            session_id VARCHAR,
            embedding VECTOR,
            content TEXT,
            timestamp TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS analytics (
            user_id VARCHAR,
            session_id VARCHAR,
            event_type VARCHAR,
            event_data JSON,
            timestamp TIMESTAMP
        );
    `)
	return err
}

// Shutdown closes database connections
func (sd *StoreDatabase) Shutdown(ctx context.Context) error {
	sd.mutex.Lock()
	defer sd.mutex.Unlock()

	if err := sd.sqliteDB.Close(); err != nil {
		log.Error().Err(err).Msg("Failed to close SQLite")
	}
	if err := sd.redisClient.Close(); err != nil {
		log.Error().Err(err).Msg("Failed to close Redis")
	}
	if err := sd.duckDB.Close(); err != nil {
		log.Error().Err(err).Msg("Failed to close DuckDB")
	}
	sd.rocksDB.Close()

	return nil
}

// SaveUser stores user data in SQLite
func (sd *StoreDatabase) SaveUser(ctx context.Context, userID string, metadata map[string]interface{}) error {
	sd.mutex.Lock()
	defer sd.mutex.Unlock()

	metadataJSON, err := json.Marshal(metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %v", err)
	}

	_, err = sd.sqliteDB.ExecContext(ctx, `
        INSERT OR REPLACE INTO users (user_id, metadata)
        VALUES (?, ?)
    `, userID, metadataJSON)
	if err != nil {
		return fmt.Errorf("failed to save user: %v", err)
	}

	log.Info().Str("user_id", userID).Msg("Saved user to SQLite")
	return nil
}

// GetUser retrieves user data from SQLite
func (sd *StoreDatabase) GetUser(ctx context.Context, userID string) (map[string]interface{}, error) {
	sd.mutex.RLock()
	defer sd.mutex.RUnlock()

	var metadataJSON string
	err := sd.sqliteDB.QueryRowContext(ctx, `
        SELECT metadata FROM users WHERE user_id = ?
    `, userID).Scan(&metadataJSON)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found: %s", userID)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %v", err)
	}

	var metadata map[string]interface{}
	if err := json.Unmarshal([]byte(metadataJSON), &metadata); err != nil {
		return nil, fmt.Errorf("failed to unmarshal metadata: %v", err)
	}

	log.Info().Str("user_id", userID).Msg("Retrieved user from SQLite")
	return metadata, nil
}

// SaveUserSettings stores user settings in SQLite
func (sd *StoreDatabase) SaveUserSettings(ctx context.Context, userID string, settings *managers.SessionSettings) error {
	sd.mutex.Lock()
	defer sd.mutex.Unlock()

	settingsJSON, err := json.Marshal(settings)
	if err != nil {
		return fmt.Errorf("failed to marshal settings: %v", err)
	}

	_, err = sd.sqliteDB.ExecContext(ctx, `
        INSERT OR REPLACE INTO user_settings (user_id, settings, updated_at)
        VALUES (?, ?, ?)
    `, userID, settingsJSON, time.Now())
	if err != nil {
		return fmt.Errorf("failed to save user settings: %v", err)
	}

	log.Info().Str("user_id", userID).Msg("Saved user settings to SQLite")
	return nil
}

// GetUserSettings retrieves user settings from SQLite
func (sd *StoreDatabase) GetUserSettings(ctx context.Context, userID string) (*managers.SessionSettings, error) {
	sd.mutex.RLock()
	defer sd.mutex.RUnlock()

	var settingsJSON string
	err := sd.sqliteDB.QueryRowContext(ctx, `
        SELECT settings FROM user_settings WHERE user_id = ?
    `, userID).Scan(&settingsJSON)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("settings not found for user: %s", userID)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get user settings: %v", err)
	}

	var settings managers.SessionSettings
	if err := json.Unmarshal([]byte(settingsJSON), &settings); err != nil {
		return nil, fmt.Errorf("failed to unmarshal settings: %v", err)
	}

	log.Info().Str("user_id", userID).Msg("Retrieved user settings from SQLite")
	return &settings, nil
}

// SaveContext stores session context in SQLite
func (sd *StoreDatabase) SaveContext(ctx context.Context, sessionID string, contextData *managers.ConversationContext) error {
	sd.mutex.Lock()
	defer sd.mutex.Unlock()

	contextJSON, err := json.Marshal(contextData)
	if err != nil {
		return fmt.Errorf("failed to marshal context: %v", err)
	}

	_, err = sd.sqliteDB.ExecContext(ctx, `
        INSERT OR REPLACE INTO contexts (session_id, context_data, updated_at)
        VALUES (?, ?, ?)
    `, sessionID, contextJSON, time.Now())
	if err != nil {
		return fmt.Errorf("failed to save context: %v", err)
	}

	log.Info().Str("session_id", sessionID).Msg("Saved context to SQLite")
	return nil
}

// GetContext retrieves session context from SQLite
func (sd *StoreDatabase) GetContext(ctx context.Context, sessionID string) (*managers.ConversationContext, error) {
	sd.mutex.RLock()
	defer sd.mutex.RUnlock()

	var contextJSON string
	err := sd.sqliteDB.QueryRowContext(ctx, `
        SELECT context_data FROM contexts WHERE session_id = ?
    `, sessionID).Scan(&contextJSON)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("context not found for session: %s", sessionID)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get context: %v", err)
	}

	var contextData managers.ConversationContext
	if err := json.Unmarshal([]byte(contextJSON), &contextData); err != nil {
		return nil, fmt.Errorf("failed to unmarshal context: %v", err)
	}

	log.Info().Str("session_id", sessionID).Msg("Retrieved context from SQLite")
	return &contextData, nil
}

// SaveEmbedding stores embeddings in DuckDB
func (sd *StoreDatabase) SaveEmbedding(ctx context.Context, sessionID string, embedding []float32, content string) error {
	sd.mutex.Lock()
	defer sd.mutex.Unlock()

	embeddingJSON, err := json.Marshal(embedding)
	if err != nil {
		return fmt.Errorf("failed to marshal embedding: %v", err)
	}

	_, err = sd.duckDB.ExecContext(ctx, `
        INSERT INTO embeddings (session_id, embedding, content, timestamp)
        VALUES (?, ?, ?, ?)
    `, sessionID, string(embeddingJSON), content, time.Now())
	if err != nil {
		return fmt.Errorf("failed to save embedding: %v", err)
	}

	log.Info().Str("session_id", sessionID).Msg("Saved embedding to DuckDB")
	return nil
}

// SearchEmbeddings performs vector search in DuckDB
func (sd *StoreDatabase) SearchEmbeddings(ctx context.Context, sessionID string, queryEmbedding []float32, limit int) ([]string, error) {
	sd.mutex.RLock()
	defer sd.mutex.RUnlock()

	queryEmbeddingJSON, err := json.Marshal(queryEmbedding)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal query embedding: %v", err)
	}

	rows, err := sd.duckDB.QueryContext(ctx, `
        SELECT content
        FROM embeddings
        WHERE session_id = ?
        ORDER BY list_cosine_similarity(CAST(embedding AS REAL[]), CAST(? AS REAL[])) DESC
        LIMIT ?
    `, sessionID, string(queryEmbeddingJSON), limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search embeddings: %v", err)
	}
	defer rows.Close()

	var results []string
	for rows.Next() {
		var content string
		if err := rows.Scan(&content); err != nil {
			return nil, fmt.Errorf("failed to scan embedding result: %v", err)
		}
		results = append(results, content)
	}

	log.Info().Str("session_id", sessionID).Int("results", len(results)).Msg("Searched embeddings in DuckDB")
	return results, nil
}

// SaveState stores session state in RocksDB
func (sd *StoreDatabase) SaveState(ctx context.Context, sessionID string, state map[string]interface{}) error {
	stateJSON, err := json.Marshal(state)
	if err != nil {
		return fmt.Errorf("failed to marshal state: %v", err)
	}

	writeOptions := rocksdb.NewDefaultWriteOptions()
	err = sd.rocksDB.Put(writeOptions, []byte(fmt.Sprintf("state:%s", sessionID)), stateJSON)
	if err != nil {
		return fmt.Errorf("failed to save state to RocksDB: %v", err)
	}

	log.Info().Str("session_id", sessionID).Msg("Saved state to RocksDB")
	return nil
}

// GetState retrieves session state from RocksDB
func (sd *StoreDatabase) GetState(ctx context.Context, sessionID string) (map[string]interface{}, error) {
	readOptions := rocksdb.NewDefaultReadOptions()
	stateJSON, err := sd.rocksDB.Get(readOptions, []byte(fmt.Sprintf("state:%s", sessionID)))
	if err != nil {
		return nil, fmt.Errorf("failed to get state from RocksDB: %v", err)
	}
	if stateJSON == nil {
		return nil, fmt.Errorf("state not found for session: %s", sessionID)
	}
	defer stateJSON.Free()

	var state map[string]interface{}
	if err := json.Unmarshal(stateJSON, &state); err != nil {
		return nil, fmt.Errorf("failed to unmarshal state: %v", err)
	}

	log.Info().Str("session_id", sessionID).Msg("Retrieved state from RocksDB")
	return state, nil
}

// SaveAnalytics logs analytics events in DuckDB
func (sd *StoreDatabase) SaveAnalytics(ctx context.Context, userID, sessionID, eventType string, eventData map[string]interface{}) error {
	sd.mutex.Lock()
	defer sd.mutex.Unlock()

	eventDataJSON, err := json.Marshal(eventData)
	if err != nil {
		return fmt.Errorf("failed to marshal event data: %v", err)
	}

	_, err = sd.duckDB.ExecContext(ctx, `
        INSERT INTO analytics (user_id, session_id, event_type, event_data, timestamp)
        VALUES (?, ?, ?, ?, ?)
    `, userID, sessionID, eventType, string(eventDataJSON), time.Now())
	if err != nil {
		return fmt.Errorf("failed to save analytics: %v", err)
	}

	log.Info().Str("user_id", userID).Str("session_id", sessionID).Str("event_type", eventType).Msg("Saved analytics to DuckDB")
	return nil
}

// SaveToS3 uploads data to S3
func (sd *StoreDatabase) SaveToS3(ctx context.Context, bucket, key, content string) error {
	_, err := sd.s3Uploader.Upload(ctx, &s3.PutObjectInput{
		Bucket: &bucket,
		Key:    &key,
		Body:   strings.NewReader(content),
	})
	if err != nil {
		return fmt.Errorf("failed to upload to S3: %v", err)
	}

	log.Info().Str("bucket", bucket).Str("key", key).Msg("Uploaded to S3")
	return nil
}

// GetFromS3 retrieves data from S3
func (sd *StoreDatabase) GetFromS3(ctx context.Context, bucket, key string) (string, error) {
	output, err := sd.s3Client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: &bucket,
		Key:    &key,
	})
	if err != nil {
		return "", fmt.Errorf("failed to get from S3: %v", err)
	}
	defer output.Body.Close()

	var buf bytes.Buffer
	_, err = io.Copy(&buf, output.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read S3 object: %v", err)
	}

	log.Info().Str("bucket", bucket).Str("key", key).Msg("Retrieved from S3")
	return buf.String(), nil
}
