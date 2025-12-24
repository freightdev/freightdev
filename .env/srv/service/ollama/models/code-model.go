// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = models/code-model.go

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

// CodeModel handles code-related inference tasks
type CodeModel struct {
	name          string
	config        *managers.ModelConfig
	modelManager  *managers.ModelManager
	tokenManager  *managers.TokenManager
	diskManager   *managers.DiskManager
	defaultParams map[string]interface{}
}

// CodeInferenceRequest represents a code-specific inference request
type CodeInferenceRequest struct {
	UserID      string                 `json:"user_id"`
	SessionID   string                 `json:"session_id"`
	Prompt      string                 `json:"prompt"`
	CodeContext *managers.CodeContext  `json:"code_context,omitempty"`
	Parameters  map[string]interface{} `json:"parameters,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// CodeInferenceResponse represents a code inference response
type CodeInferenceResponse struct {
	Content    string                 `json:"content"`
	TokensUsed int64                  `json:"tokens_used"`
	Duration   time.Duration          `json:"duration"`
	ToolCalls  []managers.ToolCall    `json:"tool_calls,omitempty"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// NewCodeModel creates a new code model
func NewCodeModel(
	name string,
	config *managers.ModelConfig,
	modelManager *managers.ModelManager,
	tokenManager *managers.TokenManager,
	diskManager *managers.DiskManager,
) *CodeModel {
	return &CodeModel{
		name:         name,
		config:       config,
		modelManager: modelManager,
		tokenManager: tokenManager,
		diskManager:  diskManager,
		defaultParams: map[string]interface{}{
			"temperature":        0.5, // Lower for precise code
			"max_tokens":         2048,
			"repetition_penalty": 1.0,
			"top_p":              0.9,
		},
	}
}

// Initialize registers the model with ModelManager
func (cm *CodeModel) Initialize(ctx context.Context) error {
	log.Info().Str("model", cm.name).Msg("Initializing code model")

	// Register with ModelManager
	if err := cm.modelManager.LoadModel(ctx, cm.name); err != nil {
		return fmt.Errorf("failed to load code model %s: %w", cm.name, err)
	}

	log.Info().Str("model", cm.name).Msg("Code model initialized")
	return nil
}

// ProcessInference handles code-specific inference
func (cm *CodeModel) ProcessInference(ctx context.Context, req *CodeInferenceRequest) (*CodeInferenceResponse, error) {
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
		ID:          fmt.Sprintf("code_%s", req.UserID),
		UserID:      req.UserID,
		SessionID:   req.SessionID,
		ModelName:   cm.name,
		RequestType: managers.InferenceTypeCode,
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

	// Save code output to disk if needed
	if req.Metadata["persist"] == true {
		if err := cm.saveCodeOutput(ctx, req, result.Content); err != nil {
			log.Warn().Err(err).Str("user_id", req.UserID).Msg("Failed to save code output")
		}
	}

	response := &CodeInferenceResponse{
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
		Msg("Processed code inference")

	return response, nil
}

// buildMessages constructs messages for inference
func (cm *CodeModel) buildMessages(req *CodeInferenceRequest) []managers.Message {
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

// buildSystemPrompt constructs a code-specific system prompt
func (cm *CodeModel) buildSystemPrompt(req *CodeInferenceRequest) string {
	prompt := "You are a code assistant specialized in generating, debugging, and analyzing code."
	if req.CodeContext != nil {
		prompt += fmt.Sprintf("\nCurrent project: %s\nLanguages: %s\nFrameworks: %s",
			req.CodeContext.CurrentProject,
			strings.Join(req.CodeContext.ProgrammingLangs, ", "),
			strings.Join(req.CodeContext.Frameworks, ", "))
	}
	return prompt
}

// mergeParameters combines default and request-specific parameters
func (cm *CodeModel) mergeParameters(params map[string]interface{}) *managers.InferenceParameters {
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

// saveCodeOutput persists code output to disk
func (cm *CodeModel) saveCodeOutput(ctx context.Context, req *CodeInferenceRequest, content string) error {
	filePath := filepath.Join(cm.diskManager.dataDir, "code_outputs", req.UserID, fmt.Sprintf("%s_%s.txt", req.SessionID, time.Now().Format("20060102_150405")))
	return cm.diskManager.WriteFile(ctx, filePath, content)
}

// Shutdown gracefully shuts down the code model
func (cm *CodeModel) Shutdown(ctx context.Context) error {
	log.Info().Str("model", cm.name).Msg("Shutting down code model")
	return cm.modelManager.UnloadModel(ctx, cm.name)
}
