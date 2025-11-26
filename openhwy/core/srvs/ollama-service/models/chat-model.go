// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = models/chat-model.go

package models

import (
	// stdlib
	"context"
	"fmt"
	"path/filepath"
	"time"

	// third-party

	// internal
	"ocs/managers"

	"github.com/rs/zerolog/log"
)

// ChatModel handles conversational inference tasks
type ChatModel struct {
	name          string
	config        *managers.ModelConfig
	modelManager  *managers.ModelManager
	tokenManager  *managers.TokenManager
	diskManager   *managers.DiskManager
	defaultParams map[string]interface{}
}

// ChatInferenceRequest represents a chat-specific inference request
type ChatInferenceRequest struct {
	UserID      string                 `json:"user_id"`
	SessionID   string                 `json:"session_id"`
	Prompt      string                 `json:"prompt"`
	Messages    []managers.Message     `json:"messages"`
	UserProfile *managers.UserProfile  `json:"user_profile,omitempty"`
	Parameters  map[string]interface{} `json:"parameters,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// ChatInferenceResponse represents a chat inference response
type ChatInferenceResponse struct {
	Content    string                 `json:"content"`
	TokensUsed int64                  `json:"tokens_used"`
	Duration   time.Duration          `json:"duration"`
	ToolCalls  []managers.ToolCall    `json:"tool_calls,omitempty"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// NewChatModel creates a new chat model
func NewChatModel(
	name string,
	config *managers.ModelConfig,
	modelManager *managers.ModelManager,
	tokenManager *managers.TokenManager,
	diskManager *managers.DiskManager,
) *ChatModel {
	return &ChatModel{
		name:         name,
		config:       config,
		modelManager: modelManager,
		tokenManager: tokenManager,
		diskManager:  diskManager,
		defaultParams: map[string]interface{}{
			"temperature":        0.7, // Balanced for conversation
			"max_tokens":         4096,
			"repetition_penalty": 1.1,
			"top_p":              0.95,
		},
	}
}

// Initialize registers the model with ModelManager
func (cm *ChatModel) Initialize(ctx context.Context) error {
	log.Info().Str("model", cm.name).Msg("Initializing chat model")

	if err := cm.modelManager.LoadModel(ctx, cm.name); err != nil {
		return fmt.Errorf("failed to load chat model %s: %w", cm.name, err)
	}

	log.Info().Str("model", cm.name).Msg("Chat model initialized")
	return nil
}

// ProcessInference handles chat-specific inference
func (cm *ChatModel) ProcessInference(ctx context.Context, req *ChatInferenceRequest) (*ChatInferenceResponse, error) {
	// Check token limits
	tokenReq := &managers.TokenUsageRequest{
		UserID:      req.UserID,
		SessionID:   req.SessionID,
		ModelName:   cm.name,
		InputTokens: int64(managers.EstimateTokens(req.Prompt)),
	}
	tokenResp, err := cm.tokenManager.CheckTokenUsage(tokenReq)
	if err != nil || !tokenResp.Allowed {
		return nil, fmt.Errorf("token check failed: %w", err)
	}

	// Build inference request
	inferenceReq := &managers.InferenceRequest{
		ID:          fmt.Sprintf("chat_%s", req.UserID),
		UserID:      req.UserID,
		SessionID:   req.SessionID,
		ModelName:   cm.name,
		RequestType: managers.InferenceTypeChat,
		Messages:    cm.buildMessages(req),
		Parameters:  cm.mergeParameters(req.Parameters),
	}

	// Process inference
	start := time.Now()
	result, err := cm.modelManager.InferenceManager().ProcessInference(ctx, inferenceReq)
	if err != nil {
		cm.modelManager.RecordModelUsage(cm.name, 0, 0, err)
		return nil, fmt.Errorf("inference failed: %w", err)
	}

	// Record usage
	cm.modelManager.RecordModelUsage(cm.name, result.Usage.TotalTokens, time.Since(start), nil)

	// Save conversation log if needed
	if req.Metadata["persist"] == true {
		if err := cm.saveChatOutput(ctx, req, result.Content); err != nil {
			log.Warn().Err(err).Str("user_id", req.UserID).Msg("Failed to save chat output")
		}
	}

	response := &ChatInferenceResponse{
		Content:    result.Content,
		TokensUsed: result.Usage.TotalTokens,
		Duration:   time.Since(start),
		ToolCalls:  result.ToolCalls,
		Metadata:   map[string]interface{}{"model": cm.name},
	}

	log.Info().
		Str("model", cm.name).
		Str("user_id", req.UserID).
		Int64("tokens", response.TokensUsed).
		Msg("Processed chat inference")

	return response, nil
}

// buildMessages constructs messages for inference
func (cm *ChatModel) buildMessages(req *ChatInferenceRequest) []managers.Message {
	messages := []managers.Message{
		{
			Role:    "system",
			Content: cm.buildSystemPrompt(req),
		},
	}
	messages = append(messages, req.Messages...)
	return messages
}

// buildSystemPrompt constructs a chat-specific system prompt
func (cm *ChatModel) buildSystemPrompt(req *ChatInferenceRequest) string {
	prompt := fmt.Sprintf("You are a conversational AI assistant using %s. Be helpful and concise.", cm.name)
	if req.UserProfile != nil {
		prompt += fmt.Sprintf("\nUser prefers %s communication style and speaks %s.",
			req.UserProfile.CommunicationStyle,
			req.UserProfile.Language)
	}
	return prompt
}

// mergeParameters combines default and request-specific parameters
func (cm *ChatModel) mergeParameters(params map[string]interface{}) *managers.InferenceParameters {
	result := &managers.InferenceParameters{
		Stream: false,
	}
	for k, v := range cm.defaultParams {
		result.Parameters[k] = v
	}
	for k, v := range params {
		result.Parameters[k] = v
	}
	return result
}

// saveChatOutput persists chat output to disk
func (cm *ChatModel) saveChatOutput(ctx context.Context, req *ChatInferenceRequest, content string) error {
	filePath := filepath.Join(cm.diskManager.dataDir, "chat_outputs", req.UserID, fmt.Sprintf("%s_%s.txt", req.SessionID, time.Now().Format("20060102_150405")))
	return cm.diskManager.WriteFile(ctx, filePath, content)
}

// Shutdown gracefully shuts down the chat model
func (cm *ChatModel) Shutdown(ctx context.Context) error {
	log.Info().Str("model", cm.name).Msg("Shutting down chat model")
	return cm.modelManager.UnloadModel(ctx, cm.name)
}
