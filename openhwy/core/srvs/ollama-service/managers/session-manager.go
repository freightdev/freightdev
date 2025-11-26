// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = managers/session-manager.go

package managers

import (
	// stdlib
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"sync"
	"time"

	"github.com/rs/zerolog/log"
	// third-party
)

// SessionManager handles persistent conversations and user context
type SessionManager struct {
	mu                 sync.RWMutex
	sessions           map[string]*Session
	userSessions       map[string][]string // userID -> sessionIDs
	configManager      *ConfigManager
	conversationMgr    *ConversationManager
	memoryManager      *MemoryManager
	cleanupInterval    time.Duration
	sessionTimeout     time.Duration
	maxSessionsPerUser int
	shutdown           chan struct{}
}

// Session represents a persistent conversation session
type Session struct {
	ID           string                 `json:"id"`
	UserID       string                 `json:"user_id"`
	Title        string                 `json:"title"`
	CreatedAt    time.Time              `json:"created_at"`
	LastActivity time.Time              `json:"last_activity"`
	MessageCount int                    `json:"message_count"`
	TokensUsed   int64                  `json:"tokens_used"`
	ModelName    string                 `json:"model_name"`
	Persona      string                 `json:"persona,omitempty"`
	Context      *SessionContext        `json:"context"`
	Metadata     map[string]interface{} `json:"metadata"`
	IsActive     bool                   `json:"is_active"`
	Settings     *SessionSettings       `json:"settings"`
}

// SessionContext holds conversation context and memory
type SessionContext struct {
	SystemPrompt    string                 `json:"system_prompt"`
	UserProfile     *UserProfile           `json:"user_profile"`
	ConversationLog []Message              `json:"conversation_log"`
	ShortTermMemory []MemoryItem           `json:"short_term_memory"`
	LongTermMemory  []MemoryItem           `json:"long_term_memory"`
	CodeContext     *CodeContext           `json:"code_context,omitempty"`
	ProjectContext  *ProjectContext        `json:"project_context,omitempty"`
	CustomContext   map[string]interface{} `json:"custom_context"`
}

// SessionSettings holds session-specific configuration
type SessionSettings struct {
	MaxTokens         int     `json:"max_tokens"`
	Temperature       float64 `json:"temperature"`
	TopP              float64 `json:"top_p"`
	RepetitionPenalty float64 `json:"repetition_penalty"`
	ContextWindow     int     `json:"context_window"`
	AutoSave          bool    `json:"auto_save"`
	PersistMemory     bool    `json:"persist_memory"`
	EnableTools       bool    `json:"enable_tools"`
	EnableCodeExec    bool    `json:"enable_code_exec"`
}

// Message represents a single message in conversation
type Message struct {
	ID        string                 `json:"id"`
	Role      string                 `json:"role"` // user, assistant, system, tool
	Content   string                 `json:"content"`
	Timestamp time.Time              `json:"timestamp"`
	Tokens    int                    `json:"tokens"`
	ModelUsed string                 `json:"model_used,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// MemoryItem represents a piece of contextual memory
type MemoryItem struct {
	ID         string                 `json:"id"`
	Type       string                 `json:"type"` // fact, preference, skill, context
	Content    string                 `json:"content"`
	Importance float64                `json:"importance"` // 0.0 - 1.0
	CreatedAt  time.Time              `json:"created_at"`
	LastUsed   time.Time              `json:"last_used"`
	UsageCount int                    `json:"usage_count"`
	Tags       []string               `json:"tags"`
	Embedding  []float64              `json:"embedding,omitempty"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// UserProfile stores user preferences and characteristics
type UserProfile struct {
	UserID             string            `json:"user_id"`
	Name               string            `json:"name"`
	PreferredModels    []string          `json:"preferred_models"`
	CommunicationStyle string            `json:"communication_style"`
	ExpertiseAreas     []string          `json:"expertise_areas"`
	LearningGoals      []string          `json:"learning_goals"`
	Preferences        map[string]string `json:"preferences"`
	Timezone           string            `json:"timezone"`
	Language           string            `json:"language"`
}

// CodeContext holds programming-specific context
type CodeContext struct {
	CurrentProject   string            `json:"current_project"`
	ProgrammingLangs []string          `json:"programming_langs"`
	Frameworks       []string          `json:"frameworks"`
	RecentFiles      []string          `json:"recent_files"`
	OpenTasks        []string          `json:"open_tasks"`
	CodeSnippets     map[string]string `json:"code_snippets"`
	ErrorHistory     []string          `json:"error_history"`
}

// ProjectContext holds project-specific information
type ProjectContext struct {
	ProjectID     string                 `json:"project_id"`
	Name          string                 `json:"name"`
	Description   string                 `json:"description"`
	Goals         []string               `json:"goals"`
	Technologies  []string               `json:"technologies"`
	Architecture  string                 `json:"architecture"`
	Documentation map[string]string      `json:"documentation"`
	Progress      map[string]interface{} `json:"progress"`
}

// NewSessionManager creates a new session manager
func NewSessionManager(configManager *ConfigManager, conversationMgr *ConversationManager, memoryManager *MemoryManager) *SessionManager {
	sm := &SessionManager{
		sessions:           make(map[string]*Session),
		userSessions:       make(map[string][]string),
		configManager:      configManager,
		conversationMgr:    conversationMgr,
		memoryManager:      memoryManager,
		cleanupInterval:    30 * time.Minute,
		sessionTimeout:     24 * time.Hour,
		maxSessionsPerUser: 50,
		shutdown:           make(chan struct{}),
	}

	// Start background cleanup
	go sm.runCleanup()

	return sm
}

// CreateSession creates a new conversation session
func (sm *SessionManager) CreateSession(ctx context.Context, userID, modelName string, settings *SessionSettings) (*Session, error) {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	// Check session limits
	userSessionCount := len(sm.userSessions[userID])
	if userSessionCount >= sm.maxSessionsPerUser {
		return nil, fmt.Errorf("maximum sessions reached for user: %d", sm.maxSessionsPerUser)
	}

	// Generate session ID
	sessionID, err := generateSessionID()
	if err != nil {
		return nil, fmt.Errorf("failed to generate session ID: %w", err)
	}

	// Load user profile
	userProfile, err := sm.loadUserProfile(ctx, userID)
	if err != nil {
		log.Warn().Err(err).Str("user_id", userID).Msg("Failed to load user profile, using default")
		userProfile = sm.createDefaultUserProfile(userID)
	}

	// Set default settings if not provided
	if settings == nil {
		settings = sm.getDefaultSettings()
	}

	// Create session context
	context := &SessionContext{
		SystemPrompt:    sm.buildSystemPrompt(modelName, userProfile),
		UserProfile:     userProfile,
		ConversationLog: make([]Message, 0),
		ShortTermMemory: make([]MemoryItem, 0),
		LongTermMemory:  make([]MemoryItem, 0),
		CustomContext:   make(map[string]interface{}),
	}

	// Create session
	session := &Session{
		ID:           sessionID,
		UserID:       userID,
		Title:        fmt.Sprintf("Chat %s", time.Now().Format("Jan 02, 15:04")),
		CreatedAt:    time.Now(),
		LastActivity: time.Now(),
		MessageCount: 0,
		TokensUsed:   0,
		ModelName:    modelName,
		Context:      context,
		Metadata:     make(map[string]interface{}),
		IsActive:     true,
		Settings:     settings,
	}

	// Store session
	sm.sessions[sessionID] = session
	sm.userSessions[userID] = append(sm.userSessions[userID], sessionID)

	log.Info().
		Str("session_id", sessionID).
		Str("user_id", userID).
		Str("model", modelName).
		Msg("Created new session")

	return session, nil
}

// GetSession retrieves a session by ID
func (sm *SessionManager) GetSession(sessionID string) (*Session, bool) {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	session, exists := sm.sessions[sessionID]
	if exists {
		// Update last activity
		session.LastActivity = time.Now()
	}
	return session, exists
}

// GetUserSessions retrieves all sessions for a user
func (sm *SessionManager) GetUserSessions(userID string) []*Session {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	sessionIDs, exists := sm.userSessions[userID]
	if !exists {
		return []*Session{}
	}

	sessions := make([]*Session, 0, len(sessionIDs))
	for _, sessionID := range sessionIDs {
		if session, exists := sm.sessions[sessionID]; exists {
			sessions = append(sessions, session)
		}
	}

	return sessions
}

// AddMessage adds a message to a session
func (sm *SessionManager) AddMessage(sessionID string, role, content string, metadata map[string]interface{}) (*Message, error) {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	session, exists := sm.sessions[sessionID]
	if !exists {
		return nil, fmt.Errorf("session not found: %s", sessionID)
	}

	// Generate message ID
	messageID, err := generateMessageID()
	if err != nil {
		return nil, fmt.Errorf("failed to generate message ID: %w", err)
	}

	// Create message
	message := Message{
		ID:        messageID,
		Role:      role,
		Content:   content,
		Timestamp: time.Now(),
		Tokens:    estimateTokens(content), // Simple estimation
		Metadata:  metadata,
	}

	// Add to conversation log
	session.Context.ConversationLog = append(session.Context.ConversationLog, message)
	session.MessageCount++
	session.TokensUsed += int64(message.Tokens)
	session.LastActivity = time.Now()

	// Trim context if needed
	sm.trimContextWindow(session)

	// Extract and store memory items
	if role == "user" || role == "assistant" {
		sm.extractMemoryItems(session, &message)
	}

	log.Debug().
		Str("session_id", sessionID).
		Str("role", role).
		Int("tokens", message.Tokens).
		Msg("Added message to session")

	return &message, nil
}

// UpdateSessionTitle updates the session title
func (sm *SessionManager) UpdateSessionTitle(sessionID, title string) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	session, exists := sm.sessions[sessionID]
	if !exists {
		return fmt.Errorf("session not found: %s", sessionID)
	}

	session.Title = title
	session.LastActivity = time.Now()
	return nil
}

// DeleteSession deletes a session
func (sm *SessionManager) DeleteSession(ctx context.Context, sessionID string) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	session, exists := sm.sessions[sessionID]
	if !exists {
		return fmt.Errorf("session not found: %s", sessionID)
	}

	// Remove from user sessions
	userSessions := sm.userSessions[session.UserID]
	for i, id := range userSessions {
		if id == sessionID {
			sm.userSessions[session.UserID] = append(userSessions[:i], userSessions[i+1:]...)
			break
		}
	}

	// Persist important memories before deletion
	if session.Settings.PersistMemory {
		sm.persistSessionMemories(ctx, session)
	}

	delete(sm.sessions, sessionID)

	log.Info().
		Str("session_id", sessionID).
		Str("user_id", session.UserID).
		Msg("Deleted session")

	return nil
}

// GetSessionContext gets formatted context for model inference
func (sm *SessionManager) GetSessionContext(sessionID string, includeMemories bool) ([]Message, error) {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	session, exists := sm.sessions[sessionID]
	if !exists {
		return nil, fmt.Errorf("session not found: %s", sessionID)
	}

	messages := make([]Message, 0)

	// Add system prompt
	if session.Context.SystemPrompt != "" {
		messages = append(messages, Message{
			Role:    "system",
			Content: session.Context.SystemPrompt,
		})
	}

	// Add relevant memories if requested
	if includeMemories {
		memoryContext := sm.buildMemoryContext(session)
		if memoryContext != "" {
			messages = append(messages, Message{
				Role:    "system",
				Content: memoryContext,
			})
		}
	}

	// Add conversation history
	messages = append(messages, session.Context.ConversationLog...)

	return messages, nil
}

// Helper functions

func generateSessionID() (string, error) {
	bytes := make([]byte, 16)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return "sess_" + hex.EncodeToString(bytes), nil
}

func generateMessageID() (string, error) {
	bytes := make([]byte, 8)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return "msg_" + hex.EncodeToString(bytes), nil
}

func estimateTokens(content string) int {
	// Rough estimation: ~4 characters per token
	return len(content) / 4
}

func (sm *SessionManager) getDefaultSettings() *SessionSettings {
	return &SessionSettings{
		MaxTokens:         2048,
		Temperature:       0.7,
		TopP:              0.9,
		RepetitionPenalty: 1.1,
		ContextWindow:     4096,
		AutoSave:          true,
		PersistMemory:     true,
		EnableTools:       true,
		EnableCodeExec:    false,
	}
}

func (sm *SessionManager) createDefaultUserProfile(userID string) *UserProfile {
	return &UserProfile{
		UserID:             userID,
		Name:               "User",
		PreferredModels:    []string{"llama3.2"},
		CommunicationStyle: "helpful",
		ExpertiseAreas:     []string{},
		LearningGoals:      []string{},
		Preferences:        make(map[string]string),
		Timezone:           "UTC",
		Language:           "en",
	}
}

func (sm *SessionManager) buildSystemPrompt(modelName string, userProfile *UserProfile) string {
	// TODO: Build dynamic system prompt based on model and user profile
	return fmt.Sprintf("You are a helpful AI assistant using the %s model. The user prefers a %s communication style.",
		modelName, userProfile.CommunicationStyle)
}

func (sm *SessionManager) trimContextWindow(session *Session) {
	maxMessages := session.Settings.ContextWindow / 100 // Rough estimation
	if len(session.Context.ConversationLog) > maxMessages {
		// Keep recent messages, move older ones to long-term memory
		oldMessages := session.Context.ConversationLog[:len(session.Context.ConversationLog)-maxMessages]
		session.Context.ConversationLog = session.Context.ConversationLog[len(session.Context.ConversationLog)-maxMessages:]

		// TODO: Summarize old messages and store in memory
		for _, msg := range oldMessages {
			sm.extractMemoryItems(session, &msg)
		}
	}
}

func (sm *SessionManager) extractMemoryItems(session *Session, message *Message) {
	// TODO: Implement memory extraction logic
	// This would analyze message content and extract important facts, preferences, etc.
}

func (sm *SessionManager) buildMemoryContext(session *Session) string {
	// TODO: Build context string from relevant memories
	return ""
}

func (sm *SessionManager) loadUserProfile(ctx context.Context, userID string) (*UserProfile, error) {
	// TODO: Load from persistent storage
	return sm.createDefaultUserProfile(userID), nil
}

func (sm *SessionManager) persistSessionMemories(ctx context.Context, session *Session) {
	// TODO: Persist important memories to long-term storage
}

func (sm *SessionManager) runCleanup() {
	ticker := time.NewTicker(sm.cleanupInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			sm.cleanupExpiredSessions()
		case <-sm.shutdown:
			return
		}
	}
}

func (sm *SessionManager) cleanupExpiredSessions() {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	now := time.Now()
	expiredSessions := make([]string, 0)

	for sessionID, session := range sm.sessions {
		if now.Sub(session.LastActivity) > sm.sessionTimeout {
			expiredSessions = append(expiredSessions, sessionID)
		}
	}

	for _, sessionID := range expiredSessions {
		session := sm.sessions[sessionID]

		// Persist memories if configured
		if session.Settings.PersistMemory {
			go sm.persistSessionMemories(context.Background(), session)
		}

		// Remove from user sessions
		userSessions := sm.userSessions[session.UserID]
		for i, id := range userSessions {
			if id == sessionID {
				sm.userSessions[session.UserID] = append(userSessions[:i], userSessions[i+1:]...)
				break
			}
		}

		delete(sm.sessions, sessionID)

		log.Info().
			Str("session_id", sessionID).
			Str("user_id", session.UserID).
			Msg("Cleaned up expired session")
	}
}

// Shutdown gracefully shuts down the session manager
func (sm *SessionManager) Shutdown(ctx context.Context) error {
	log.Info().Msg("Shutting down session manager")
	close(sm.shutdown)

	// Persist all active sessions
	for _, session := range sm.sessions {
		if session.Settings.PersistMemory {
			sm.persistSessionMemories(ctx, session)
		}
	}

	log.Info().Msg("Session manager shutdown complete")
	return nil
}
