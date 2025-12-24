// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = models/reasoning-model.go

package models

import (
	// stdlib
	"context"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	// third-party

	// internal
	"ocs/managers"

	"github.com/rs/zerolog/log"
)

// ReasoningModel handles reasoning and analytical inference tasks
type ReasoningModel struct {
	name          string
	config        *managers.ModelConfig
	modelManager  *managers.ModelManager
	tokenManager  *managers.TokenManager
	diskManager   *managers.DiskManager
	defaultParams map[string]interface{}
}

// ReasoningInferenceRequest represents a reasoning-specific inference request
type ReasoningInferenceRequest struct {
	UserID     string                        `json:"user_id"`
	SessionID  string                        `json:"session_id"`
	Prompt     string                        `json:"prompt"`
	Context    *managers.ConversationContext `json:"context,omitempty"`
	Parameters map[string]interface{}        `json:"parameters,omitempty"`
	Metadata   map[string]interface{}        `json:"metadata,omitempty"`
}

// ReasoningInferenceResponse represents a reasoning inference response
type ReasoningInferenceResponse struct {
	Content    string                 `json:"content"`
	TokensUsed int64                  `json:"tokens_used"`
	Duration   time.Duration          `json:"duration"`
	ToolCalls  []managers.ToolCall    `json:"tool_calls,omitempty"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// NewReasoningModel creates a new reasoning model
func NewReasoningModel(
	name string,
	config *managers.ModelConfig,
	modelManager *managers.ModelManager,
	tokenManager *managers.TokenManager,
	diskManager *managers.DiskManager,
) *ReasoningModel {
	return &ReasoningModel{
		name:         name,
		config:       config,
		modelManager: modelManager,
		tokenManager: tokenManager,
		diskManager:  diskManager,
		defaultParams: map[string]interface{}{
			"temperature":        0.3, // Low for precise reasoning
			"max_tokens":         8192,
			"repetition_penalty": 1.0,
			"top_p":              0.9,
		},
	}
}

// Initialize registers the model with ModelManager
func (cm *ReasoningModel) Initialize(ctx context.Context) error {
	log.Info().Str("model", cm.name).Msg("Initializing reasoning model")

	if err := cm.modelManager.LoadModel(ctx, cm.name); err != nil {
		return fmt.Errorf("failed to load reasoning model %s: %w", cm.name, err)
	}

	log.Info().Str("model", cm.name).Msg("Reasoning model initialized")
	return nil
}

// ProcessInference handles reasoning-specific inference
func (cm *ReasoningModel) ProcessInference(ctx context.Context, req *ReasoningInferenceRequest) (*ReasoningInferenceResponse, error) {
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
		ID:          fmt.Sprintf("reasoning_%s", req.UserID),
		UserID:      req.UserID,
		SessionID:   req.SessionID,
		ModelName:   cm.name,
		RequestType: managers.InferenceTypeReasoning,
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

	// Save reasoning output to disk if needed
	if req.Metadata["persist"] == true {
		if err := cm.saveReasoningOutput(ctx, req, result.Content); err != nil {
			log.Warn().Err(err).Str("user_id", req.UserID).Msg("Failed to save reasoning output")
		}
	}

	response := &ReasoningInferenceResponse{
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
		Msg("Processed reasoning inference")

	return response, nil
}

// buildMessages constructs messages for inference
func (cm *ReasoningModel) buildMessages(req *ReasoningInferenceRequest) []managers.Message {
	messages := []managers.Message{
		{
			Role:    "system",
			Content: cm.buildSystemPrompt(req),
		},
		{
			Role:    "user",
			Content: req.Prompt,
		},
	}
	return messages
}

// buildSystemPrompt constructs a reasoning-specific system prompt
func (cm *ReasoningModel) buildSystemPrompt(req *ReasoningInferenceRequest) string {
	prompt := "You are a reasoning AI assistant specialized in analysis and problem-solving."
	if req.Context != nil {
		prompt += fmt.Sprintf("\nTopic: %s\nIntent: %s\nGoals: %s",
			req.Context.Topic,
			req.Context.Intent,
			strings.Join(req.Context.UserGoals, ", "))
	}
	return prompt
}

// mergeParameters combines default and request-specific parameters
func (cm *ReasoningModel) mergeParameters(params map[string]interface{}) *managers.InferenceParameters {
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

// saveReasoningOutput persists reasoning output to disk
func (cm *ReasoningModel) saveReasoningOutput(ctx context.Context, req *ReasoningInferenceRequest, content string) error {
	filePath := filepath.Join(cm.diskManager.dataDir, "reasoning_outputs", req.UserID, fmt.Sprintf("%s_%s.txt", req.SessionID, time.Now().Format("20060102_150405")))
	return cm.diskManager.WriteFile(ctx, filePath, content)
}

// Shutdown gracefully shuts down the reasoning model
func (cm *ReasoningModel) Shutdown(ctx context.Context) error {
	log.Info().Str("model", cm.name).Msg("Shutting down reasoning model")
	return cm.modelManager.UnloadModel(ctx, cm.name)
}
