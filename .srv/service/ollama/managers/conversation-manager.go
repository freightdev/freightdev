// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = managers/conversation-manager.go

// managers/conversation-manager.go
package managers

import (
	// stdlib
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"

	// third-party
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

// ConversationManager handles conversation flow, threading, and orchestration
type ConversationManager struct {
	mu                      sync.RWMutex
	activeConversations     map[string]*Conversation
	conversationsByUser     map[string][]*Conversation
	conversationsBySession  map[string]*Conversation
	configManager           *ConfigManager
	sessionManager          *SessionManager
	memoryManager           *MemoryManager
	tokenManager            *TokenManager
	inferenceManager        *InferenceManager
	conversationTimeout     time.Duration
	maxConversationsPerUser int
	shutdown                chan struct{}
}

// Conversation represents an active conversation thread
type Conversation struct {
	ID               string                 `json:"id"`
	SessionID        string                 `json:"session_id"`
	UserID           string                 `json:"user_id"`
	Title            string                 `json:"title"`
	Status           ConversationStatus     `json:"status"`
	CreatedAt        time.Time              `json:"created_at"`
	LastActivity     time.Time              `json:"last_activity"`
	MessageCount     int                    `json:"message_count"`
	TokensUsed       int64                  `json:"tokens_used"`
	CurrentModel     string                 `json:"current_model"`
	ConversationFlow *ConversationFlow      `json:"conversation_flow"`
	Context          *ConversationContext   `json:"context"`
	Participants     []*Participant         `json:"participants"`
	Settings         *ConversationSettings  `json:"settings"`
	Threading        *ThreadingInfo         `json:"threading"`
	Metadata         map[string]interface{} `json:"metadata"`
	mu               sync.RWMutex           `json:"-"`
}

// ConversationStatus defines conversation states
type ConversationStatus string

const (
	ConversationStatusActive    ConversationStatus = "active"
	ConversationStatusPaused    ConversationStatus = "paused"
	ConversationStatusWaiting   ConversationStatus = "waiting"
	ConversationStatusCompleted ConversationStatus = "completed"
	ConversationStatusError     ConversationStatus = "error"
	ConversationStatusArchived  ConversationStatus = "archived"
)

// ConversationFlow manages the flow of conversation
type ConversationFlow struct {
	CurrentStep      int                    `json:"current_step"`
	Steps            []*ConversationStep    `json:"steps"`
	FlowType         ConversationFlowType   `json:"flow_type"`
	IsMultiTurn      bool                   `json:"is_multi_turn"`
	RequiresFollowup bool                   `json:"requires_followup"`
	PendingActions   []*PendingAction       `json:"pending_actions"`
	FlowState        map[string]interface{} `json:"flow_state"`
	AutoContinue     bool                   `json:"auto_continue"`
	MaxSteps         int                    `json:"max_steps"`
}

// ConversationStep represents a step in conversation flow
type ConversationStep struct {
	ID          string                 `json:"id"`
	Type        ConversationStepType   `json:"type"`
	Description string                 `json:"description"`
	Required    bool                   `json:"required"`
	Completed   bool                   `json:"completed"`
	UserInput   string                 `json:"user_input,omitempty"`
	AIResponse  string                 `json:"ai_response,omitempty"`
	ToolCalls   []ToolCall             `json:"tool_calls,omitempty"`
	Validation  *StepValidation        `json:"validation,omitempty"`
	NextSteps   []string               `json:"next_steps,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
	CompletedAt time.Time              `json:"completed_at,omitempty"`
}

// ConversationFlowType defines types of conversation flows
type ConversationFlowType string

const (
	FlowTypeLinear        ConversationFlowType = "linear"
	FlowTypeBranching     ConversationFlowType = "branching"
	FlowTypeIterative     ConversationFlowType = "iterative"
	FlowTypeCollaborative ConversationFlowType = "collaborative"
	FlowTypeDebug         ConversationFlowType = "debug"
	FlowTypeTutorial      ConversationFlowType = "tutorial"
	FlowTypeAnalysis      ConversationFlowType = "analysis"
)

// ConversationStepType defines types of conversation steps
type ConversationStepType string

const (
	StepTypeUserInput     ConversationStepType = "user_input"
	StepTypeAIResponse    ConversationStepType = "ai_response"
	StepTypeToolExecution ConversationStepType = "tool_execution"
	StepTypeValidation    ConversationStepType = "validation"
	StepTypeDecision      ConversationStepType = "decision"
	StepTypeSummary       ConversationStepType = "summary"
	StepTypeFollowup      ConversationStepType = "followup"
)

// ConversationContext holds contextual information
type ConversationContext struct {
	Topic          string                 `json:"topic"`
	Intent         ConversationIntent     `json:"intent"`
	Entities       []*Entity              `json:"entities"`
	CurrentTask    string                 `json:"current_task,omitempty"`
	PreviousTask   string                 `json:"previous_task,omitempty"`
	UserGoals      []string               `json:"user_goals"`
	CompletedGoals []string               `json:"completed_goals"`
	ContextHistory []*ContextSnapshot     `json:"context_history"`
	WorkingMemory  map[string]interface{} `json:"working_memory"`
	SharedState    map[string]interface{} `json:"shared_state"`
	LastUpdated    time.Time              `json:"last_updated"`
}

// ConversationIntent defines user intent
type ConversationIntent string

const (
	IntentQuestion      ConversationIntent = "question"
	IntentRequest       ConversationIntent = "request"
	IntentInstruction   ConversationIntent = "instruction"
	IntentCollaboration ConversationIntent = "collaboration"
	IntentDebug         ConversationIntent = "debug"
	IntentLearning      ConversationIntent = "learning"
	IntentCreative      ConversationIntent = "creative"
	IntentAnalysis      ConversationIntent = "analysis"
)

// Entity represents extracted entities from conversation
type Entity struct {
	Name       string                 `json:"name"`
	Type       string                 `json:"type"`
	Value      string                 `json:"value"`
	Confidence float64                `json:"confidence"`
	Position   int                    `json:"position"`
	Context    string                 `json:"context"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// Participant represents conversation participants
type Participant struct {
	ID           string                 `json:"id"`
	Type         ParticipantType        `json:"type"`
	Name         string                 `json:"name"`
	Role         string                 `json:"role"`
	IsActive     bool                   `json:"is_active"`
	LastActivity time.Time              `json:"last_activity"`
	Permissions  []string               `json:"permissions"`
	Metadata     map[string]interface{} `json:"metadata"`
}

// ParticipantType defines participant types
type ParticipantType string

const (
	ParticipantTypeHuman ParticipantType = "human"
	ParticipantTypeAI    ParticipantType = "ai"
	ParticipantTypeTool  ParticipantType = "tool"
	ParticipantTypeAgent ParticipantType = "agent"
)

// ConversationSettings holds conversation configuration
type ConversationSettings struct {
	AllowMultiTurn      bool     `json:"allow_multi_turn"`
	AllowToolUse        bool     `json:"allow_tool_use"`
	AllowCodeExecution  bool     `json:"allow_code_execution"`
	RequireConfirmation bool     `json:"require_confirmation"`
	AutoSave            bool     `json:"auto_save"`
	SaveInterval        int      `json:"save_interval"` // seconds
	MaxMessageLength    int      `json:"max_message_length"`
	AllowedModels       []string `json:"allowed_models"`
	PreferredLanguage   string   `json:"preferred_language"`
	ConversationStyle   string   `json:"conversation_style"`
	SafetyLevel         string   `json:"safety_level"`
	PrivacyMode         bool     `json:"privacy_mode"`
}

// ThreadingInfo manages conversation threading
type ThreadingInfo struct {
	ParentConversationID string          `json:"parent_conversation_id,omitempty"`
	ChildConversations   []string        `json:"child_conversations"`
	ThreadDepth          int             `json:"thread_depth"`
	ThreadBranches       []*ThreadBranch `json:"thread_branches"`
	CurrentBranch        string          `json:"current_branch"`
	MergePoints          []*MergePoint   `json:"merge_points"`
}

// ThreadBranch represents a conversation branch
type ThreadBranch struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
	BranchPoint int       `json:"branch_point"` // Message index where branch occurred
	IsActive    bool      `json:"is_active"`
}

// MergePoint represents points where branches can merge
type MergePoint struct {
	ID         string    `json:"id"`
	MessageID  string    `json:"message_id"`
	BranchIDs  []string  `json:"branch_ids"`
	MergeType  string    `json:"merge_type"`
	CreatedAt  time.Time `json:"created_at"`
	IsResolved bool      `json:"is_resolved"`
}

// PendingAction represents actions waiting to be executed
type PendingAction struct {
	ID          string                 `json:"id"`
	Type        string                 `json:"type"`
	Description string                 `json:"description"`
	Parameters  map[string]interface{} `json:"parameters"`
	Priority    int                    `json:"priority"`
	CreatedAt   time.Time              `json:"created_at"`
	ExpiresAt   time.Time              `json:"expires_at"`
	Status      string                 `json:"status"`
}

// StepValidation defines validation rules for conversation steps
type StepValidation struct {
	Required      bool     `json:"required"`
	MinLength     int      `json:"min_length,omitempty"`
	MaxLength     int      `json:"max_length,omitempty"`
	Pattern       string   `json:"pattern,omitempty"`
	AllowedValues []string `json:"allowed_values,omitempty"`
	ValidationFn  string   `json:"validation_fn,omitempty"`
}

// ContextSnapshot captures conversation context at a point in time
type ContextSnapshot struct {
	Timestamp time.Time              `json:"timestamp"`
	MessageID string                 `json:"message_id"`
	Topic     string                 `json:"topic"`
	Intent    ConversationIntent     `json:"intent"`
	Entities  []*Entity              `json:"entities"`
	UserState map[string]interface{} `json:"user_state"`
}

// ConversationEvent represents events in conversation lifecycle
type ConversationEvent struct {
	ID             string                 `json:"id"`
	ConversationID string                 `json:"conversation_id"`
	Type           string                 `json:"type"`
	Description    string                 `json:"description"`
	Data           map[string]interface{} `json:"data"`
	Timestamp      time.Time              `json:"timestamp"`
	UserID         string                 `json:"user_id"`
}

// NewConversationManager creates a new conversation manager
func NewConversationManager(
	configManager *ConfigManager,
	sessionManager *SessionManager,
	memoryManager *MemoryManager,
	tokenManager *TokenManager,
	inferenceManager *InferenceManager,
) *ConversationManager {
	return &ConversationManager{
		activeConversations:     make(map[string]*Conversation),
		conversationsByUser:     make(map[string][]*Conversation),
		conversationsBySession:  make(map[string]*Conversation),
		configManager:           configManager,
		sessionManager:          sessionManager,
		memoryManager:           memoryManager,
		tokenManager:            tokenManager,
		inferenceManager:        inferenceManager,
		conversationTimeout:     2 * time.Hour,
		maxConversationsPerUser: 10,
		shutdown:                make(chan struct{}),
	}
}

// StartConversation initiates a new conversation
func (cm *ConversationManager) StartConversation(ctx context.Context, userID, sessionID string, settings *ConversationSettings) (*Conversation, error) {
	cm.mu.Lock()
	defer cm.mu.Unlock()

	// Check user conversation limits
	if len(cm.conversationsByUser[userID]) >= cm.maxConversationsPerUser {
		return nil, fmt.Errorf("maximum conversations reached for user")
	}

	// Create conversation
	conversation := &Conversation{
		ID:           cm.generateConversationID(),
		SessionID:    sessionID,
		UserID:       userID,
		Title:        fmt.Sprintf("Conversation %s", time.Now().Format("15:04")),
		Status:       ConversationStatusActive,
		CreatedAt:    time.Now(),
		LastActivity: time.Now(),
		CurrentModel: "llama3.2", // Default model
		ConversationFlow: &ConversationFlow{
			FlowType:     FlowTypeLinear,
			IsMultiTurn:  true,
			AutoContinue: true,
			MaxSteps:     100,
			Steps:        make([]*ConversationStep, 0),
			FlowState:    make(map[string]interface{}),
		},
		Context: &ConversationContext{
			Intent:         IntentQuestion,
			Entities:       make([]*Entity, 0),
			UserGoals:      make([]string, 0),
			CompletedGoals: make([]string, 0),
			ContextHistory: make([]*ContextSnapshot, 0),
			WorkingMemory:  make(map[string]interface{}),
			SharedState:    make(map[string]interface{}),
			LastUpdated:    time.Now(),
		},
		Participants: []*Participant{
			{
				ID:           userID,
				Type:         ParticipantTypeHuman,
				Name:         "User",
				Role:         "user",
				IsActive:     true,
				LastActivity: time.Now(),
				Permissions:  []string{"send", "receive", "tools"},
			},
			{
				ID:           "assistant",
				Type:         ParticipantTypeAI,
				Name:         "Assistant",
				Role:         "assistant",
				IsActive:     true,
				LastActivity: time.Now(),
				Permissions:  []string{"send", "receive", "tools", "execute"},
			},
		},
		Settings: cm.getDefaultSettings(),
		Threading: &ThreadingInfo{
			ChildConversations: make([]string, 0),
			ThreadBranches:     make([]*ThreadBranch, 0),
			MergePoints:        make([]*MergePoint, 0),
		},
		Metadata: make(map[string]interface{}),
	}

	// Apply custom settings
	if settings != nil {
		conversation.Settings = settings
	}

	// Register conversation
	cm.activeConversations[conversation.ID] = conversation
	cm.conversationsByUser[userID] = append(cm.conversationsByUser[userID], conversation)
	cm.conversationsBySession[sessionID] = conversation

	log.Info().
		Str("conversation_id", conversation.ID).
		Str("user_id", userID).
		Str("session_id", sessionID).
		Msg("Started new conversation")

	return conversation, nil
}

// ProcessMessage handles a message in an active conversation
func (cm *ConversationManager) ProcessMessage(ctx context.Context, conversationID string, message *Message) (*ConversationResponse, error) {
	conversation, exists := cm.getConversation(conversationID)
	if !exists {
		return nil, fmt.Errorf("conversation not found: %s", conversationID)
	}

	conversation.mu.Lock()
	defer conversation.mu.Unlock()

	// Update conversation activity
	conversation.LastActivity = time.Now()
	conversation.MessageCount++

	// Analyze message intent and extract entities
	cm.analyzeMessage(conversation, message)

	// Create conversation step for user input
	userStep := &ConversationStep{
		ID:          cm.generateStepID(),
		Type:        StepTypeUserInput,
		Description: "User input received",
		Required:    true,
		Completed:   true,
		UserInput:   message.Content,
		CompletedAt: time.Now(),
	}

	conversation.ConversationFlow.Steps = append(conversation.ConversationFlow.Steps, userStep)

	// Create inference request
	inferenceReq := &InferenceRequest{
		ID:          cm.generateRequestID(),
		UserID:      conversation.UserID,
		SessionID:   conversation.SessionID,
		ModelName:   conversation.CurrentModel,
		RequestType: cm.mapIntentToInferenceType(conversation.Context.Intent),
		Messages:    cm.buildInferenceMessages(conversation, message),
	}

	// Process inference
	result, err := cm.inferenceManager.ProcessInference(ctx, inferenceReq)
	if err != nil {
		conversation.Status = ConversationStatusError
		return nil, fmt.Errorf("inference failed: %w", err)
	}

	// Create conversation step for AI response
	aiStep := &ConversationStep{
		ID:          cm.generateStepID(),
		Type:        StepTypeAIResponse,
		Description: "AI response generated",
		Required:    true,
		Completed:   true,
		AIResponse:  result.Content,
		CompletedAt: time.Now(),
	}

	conversation.ConversationFlow.Steps = append(conversation.ConversationFlow.Steps, aiStep)

	// Update conversation state
	conversation.TokensUsed += int64(result.Usage.TotalTokens)
	conversation.ConversationFlow.CurrentStep = len(conversation.ConversationFlow.Steps) - 1

	// Create response
	response := &ConversationResponse{
		ConversationID: conversationID,
		MessageID:      cm.generateMessageID(),
		Content:        result.Content,
		Type:           "text",
		Status:         "completed",
		TokensUsed:     int64(result.Usage.TotalTokens),
		ModelUsed:      result.ModelUsed,
		Timestamp:      time.Now(),
		Metadata: map[string]interface{}{
			"step_id":           aiStep.ID,
			"response_time":     result.Duration,
			"conversation_flow": conversation.ConversationFlow.FlowType,
		},
	}

	// Handle tool calls if any
	if len(result.ToolCalls) > 0 {
		response.ToolCalls = result.ToolCalls
		response.RequiresToolExecution = true
		conversation.Status = ConversationStatusWaiting
	}
	var log = zerolog.New(os.Stdout).With().Timestamp().Logger()
	log.Info().
		Str("conversation_id", conversationID).
		Str("user_id", conversation.UserID).
		Int("step", conversation.ConversationFlow.CurrentStep).
		Int64("tokens", int64(result.Usage.TotalTokens)).
		Msg("Processed conversation message")

	return response, nil
}

// ProcessStreamingMessage handles streaming message processing
func (cm *ConversationManager) ProcessStreamingMessage(ctx context.Context, conversationID string, message *Message) (<-chan *ConversationStreamChunk, error) {
	conversation, exists := cm.getConversation(conversationID)
	if !exists {
		return nil, fmt.Errorf("conversation not found: %s", conversationID)
	}

	// Create streaming response channel
	responseChan := make(chan *ConversationStreamChunk, 100)

	go func() {
		defer close(responseChan)

		conversation.mu.Lock()
		defer conversation.mu.Unlock()

		// Update conversation activity
		conversation.LastActivity = time.Now()
		conversation.MessageCount++

		// Analyze message
		cm.analyzeMessage(conversation, message)

		// Create user step
		userStep := &ConversationStep{
			ID:          cm.generateStepID(),
			Type:        StepTypeUserInput,
			Description: "User input received",
			Required:    true,
			Completed:   true,
			UserInput:   message.Content,
			CompletedAt: time.Now(),
		}

		conversation.ConversationFlow.Steps = append(conversation.ConversationFlow.Steps, userStep)

		// Create inference request for streaming
		inferenceReq := &InferenceRequest{
			ID:          cm.generateRequestID(),
			UserID:      conversation.UserID,
			SessionID:   conversation.SessionID,
			ModelName:   conversation.CurrentModel,
			RequestType: cm.mapIntentToInferenceType(conversation.Context.Intent),
			Messages:    cm.buildInferenceMessages(conversation, message),
			Parameters:  &InferenceParameters{Stream: true},
		}

		// Start streaming inference
		streamChan, err := cm.inferenceManager.ProcessStreamingInference(ctx, inferenceReq)
		if err != nil {
			responseChan <- &ConversationStreamChunk{
				ConversationID: conversationID,
				Error:          err.Error(),
				Done:           true,
			}
			return
		}

		// Relay streaming chunks
		fullResponse := ""
		for chunk := range streamChan {
			fullResponse += chunk.Content

			conversationChunk := &ConversationStreamChunk{
				ConversationID: conversationID,
				Content:        chunk.Content,
				Done:           chunk.Done,
				TokenCount:     chunk.TokenCount,
				Error:          chunk.Error,
				Timestamp:      time.Now(),
			}

			select {
			case responseChan <- conversationChunk:
			case <-ctx.Done():
				return
			}

			if chunk.Done {
				// Create AI step for completed response
				aiStep := &ConversationStep{
					ID:          cm.generateStepID(),
					Type:        StepTypeAIResponse,
					Description: "AI response generated",
					Required:    true,
					Completed:   true,
					AIResponse:  fullResponse,
					CompletedAt: time.Now(),
				}

				conversation.ConversationFlow.Steps = append(conversation.ConversationFlow.Steps, aiStep)
				conversation.ConversationFlow.CurrentStep = len(conversation.ConversationFlow.Steps) - 1
				break
			}
		}
	}()

	return responseChan, nil
}

// ConversationResponse represents a response in a conversation
type ConversationResponse struct {
	ConversationID        string                 `json:"conversation_id"`
	MessageID             string                 `json:"message_id"`
	Content               string                 `json:"content"`
	Type                  string                 `json:"type"`
	Status                string                 `json:"status"`
	TokensUsed            int64                  `json:"tokens_used"`
	ModelUsed             string                 `json:"model_used"`
	Timestamp             time.Time              `json:"timestamp"`
	RequiresToolExecution bool                   `json:"requires_tool_execution"`
	ToolCalls             []ToolCall             `json:"tool_calls,omitempty"`
	Suggestions           []string               `json:"suggestions,omitempty"`
	Metadata              map[string]interface{} `json:"metadata"`
}

// ConversationStreamChunk represents a streaming chunk in conversation
type ConversationStreamChunk struct {
	ConversationID string    `json:"conversation_id"`
	Content        string    `json:"content"`
	Done           bool      `json:"done"`
	TokenCount     int       `json:"token_count"`
	Error          string    `json:"error,omitempty"`
	Timestamp      time.Time `json:"timestamp"`
}

// Helper functions

func (cm *ConversationManager) getConversation(id string) (*Conversation, bool) {
	cm.mu.RLock()
	defer cm.mu.RUnlock()

	conv, exists := cm.activeConversations[id]
	return conv, exists
}

func (cm *ConversationManager) generateConversationID() string {
	bytes := make([]byte, 8)
	rand.Read(bytes)
	return "conv_" + hex.EncodeToString(bytes)
}

func (cm *ConversationManager) generateStepID() string {
	bytes := make([]byte, 4)
	rand.Read(bytes)
	return "step_" + hex.EncodeToString(bytes)
}

func (cm *ConversationManager) generateRequestID() string {
	bytes := make([]byte, 6)
	rand.Read(bytes)
	return "req_" + hex.EncodeToString(bytes)
}

func (cm *ConversationManager) generateMessageID() string {
	bytes := make([]byte, 6)
	rand.Read(bytes)
	return "msg_" + hex.EncodeToString(bytes)
}

func (cm *ConversationManager) getDefaultSettings() *ConversationSettings {
	return &ConversationSettings{
		AllowMultiTurn:      true,
		AllowToolUse:        true,
		AllowCodeExecution:  false,
		RequireConfirmation: false,
		AutoSave:            true,
		SaveInterval:        30,
		MaxMessageLength:    10000,
		AllowedModels:       []string{"llama3.2", "codellama"},
		PreferredLanguage:   "en",
		ConversationStyle:   "helpful",
		SafetyLevel:         "standard",
		PrivacyMode:         false,
	}
}

func (cm *ConversationManager) analyzeMessage(conversation *Conversation, message *Message) {
	// Simple intent analysis (in practice, you'd use NLP models)
	content := strings.ToLower(message.Content)

	// Determine intent
	if strings.Contains(content, "?") {
		conversation.Context.Intent = IntentQuestion
	} else if strings.Contains(content, "please") || strings.Contains(content, "can you") {
		conversation.Context.Intent = IntentRequest
	} else if strings.Contains(content, "debug") || strings.Contains(content, "error") {
		conversation.Context.Intent = IntentDebug
	} else if strings.Contains(content, "learn") || strings.Contains(content, "teach") {
		conversation.Context.Intent = IntentLearning
	} else {
		conversation.Context.Intent = IntentInstruction
	}

	// Extract simple entities (placeholder implementation)
	entities := cm.extractEntities(message.Content)
	conversation.Context.Entities = append(conversation.Context.Entities, entities...)

	// Update context snapshot
	snapshot := &ContextSnapshot{
		Timestamp: time.Now(),
		MessageID: message.ID,
		Topic:     cm.extractTopic(message.Content),
		Intent:    conversation.Context.Intent,
		Entities:  entities,
		UserState: make(map[string]interface{}),
	}

	conversation.Context.ContextHistory = append(conversation.Context.ContextHistory, snapshot)
	conversation.Context.LastUpdated = time.Now()
}

func (cm *ConversationManager) extractEntities(content string) []*Entity {
	// Placeholder entity extraction
	return []*Entity{}
}

func (cm *ConversationManager) extractTopic(content string) string {
	// Simple topic extraction (first few words)
	words := strings.Fields(content)
	if len(words) > 3 {
		return strings.Join(words[:3], " ")
	}
	return strings.Join(words, " ")
}

func (cm *ConversationManager) determineResponseStrategy(conversation *Conversation, message *Message) string {
	// Determine response strategy based on conversation flow and context
	switch conversation.Context.Intent {
	case IntentDebug:
		return "debug_assist"
	case IntentLearning:
		return "educational"
	case IntentCreative:
		return "creative"
	case IntentAnalysis:
		return "analytical"
	default:
		return "helpful"
	}
}

func (cm *ConversationManager) mapIntentToInferenceType(intent ConversationIntent) InferenceType {
	switch intent {
	case IntentDebug:
		return InferenceTypeReasoning
	case IntentLearning:
		return InferenceTypeChat
	case IntentAnalysis:
		return InferenceTypeAnalysis
	case IntentCreative:
		return InferenceTypeChat
	default:
		return InferenceTypeChat
	}
}

func (cm *ConversationManager) buildInferenceMessages(conversation *Conversation, message *Message) []Message {
	messages := make([]Message, 0)

	// Add system message based on conversation context
	systemPrompt := cm.buildSystemPrompt(conversation)
	if systemPrompt != "" {
		messages = append(messages, Message{
			Role:    "system",
			Content: systemPrompt,
		})
	}

	// Add conversation history (last few steps)
	historyLimit := 10
	steps := conversation.ConversationFlow.Steps
	startIdx := 0
	if len(steps) > historyLimit {
		startIdx = len(steps) - historyLimit
	}

	for _, step := range steps[startIdx:] {
		if step.UserInput != "" {
			messages = append(messages, Message{
				Role:    "user",
				Content: step.UserInput,
			})
		}
		if step.AIResponse != "" {
			messages = append(messages, Message{
				Role:    "assistant",
				Content: step.AIResponse,
			})
		}
	}

	// Add current message
	messages = append(messages, *message)

	return messages
}

func (cm *ConversationManager) buildSystemPrompt(conversation *Conversation) string {
	// Build system prompt based on conversation context
	prompt := fmt.Sprintf("You are a helpful AI assistant. The user's current intent is %s.", conversation.Context.Intent)

	if conversation.Context.Topic != "" {
		prompt += fmt.Sprintf(" The conversation topic is: %s.", conversation.Context.Topic)
	}

	if len(conversation.Context.UserGoals) > 0 {
		prompt += fmt.Sprintf(" The user's goals are: %s.", strings.Join(conversation.Context.UserGoals, ", "))
	}

	return prompt
}
