// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = managers/inference-manager.go

package managers

import (
	// stdlib
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/rs/zerolog/log"
	// third-party
)

// InferenceManager orchestrates AI model inference requests
type InferenceManager struct {
	mu               sync.RWMutex
	configManager    *ConfigManager
	modelManager     *ModelManager
	tokenManager     *TokenManager
	memoryManager    *MemoryManager
	sessionManager   *SessionManager
	activeInferences map[string]*InferenceRequest
	ollamaBaseURL    string
	client           *http.Client
	requestTimeout   time.Duration
	maxRetries       int
	retryDelay       time.Duration
	shutdown         chan struct{}
}

// InferenceRequest represents an active inference request
type InferenceRequest struct {
	ID            string                 `json:"id"`
	UserID        string                 `json:"user_id"`
	SessionID     string                 `json:"session_id,omitempty"`
	ModelName     string                 `json:"model_name"`
	RequestType   InferenceType          `json:"request_type"`
	Messages      []Message              `json:"messages"`
	Parameters    *InferenceParameters   `json:"parameters"`
	Status        InferenceStatus        `json:"status"`
	StartTime     time.Time              `json:"start_time"`
	EndTime       time.Time              `json:"end_time"`
	TokensUsed    int64                  `json:"tokens_used"`
	Error         string                 `json:"error,omitempty"`
	Result        *InferenceResult       `json:"result,omitempty"`
	StreamChannel chan *StreamChunk      `json:"-"`
	Context       context.Context        `json:"-"`
	CancelFunc    context.CancelFunc     `json:"-"`
	Metadata      map[string]interface{} `json:"metadata"`
}

// InferenceParameters holds model parameters for inference
type InferenceParameters struct {
	Temperature     float64                `json:"temperature,omitempty"`
	TopK            int                    `json:"top_k,omitempty"`
	TopP            float64                `json:"top_p,omitempty"`
	RepeatPenalty   float64                `json:"repeat_penalty,omitempty"`
	Seed            int                    `json:"seed,omitempty"`
	MaxTokens       int                    `json:"max_tokens,omitempty"`
	Stop            []string               `json:"stop,omitempty"`
	Stream          bool                   `json:"stream"`
	UseMemory       bool                   `json:"use_memory"`
	MemoryDepth     int                    `json:"memory_depth,omitempty"`
	Tools           []string               `json:"tools,omitempty"`
	SystemPrompt    string                 `json:"system_prompt,omitempty"`
	ContextOptimize bool                   `json:"context_optimize"`
	CustomOptions   map[string]interface{} `json:"custom_options,omitempty"`
}

// InferenceResult holds the result of an inference
type InferenceResult struct {
	Content          string                 `json:"content"`
	TokensGenerated  int                    `json:"tokens_generated"`
	TokensInput      int                    `json:"tokens_input"`
	Duration         time.Duration          `json:"duration"`
	ModelUsed        string                 `json:"model_used"`
	FinishReason     string                 `json:"finish_reason"`
	Usage            *TokenUsage            `json:"usage"`
	ToolCalls        []ToolCall             `json:"tool_calls,omitempty"`
	Metadata         map[string]interface{} `json:"metadata,omitempty"`
	PerformanceStats *PerformanceStats      `json:"performance_stats,omitempty"`
}

// InferenceType defines different types of inference requests
type InferenceType string

const (
	InferenceTypeChat       InferenceType = "chat"
	InferenceTypeCompletion InferenceType = "completion"
	InferenceTypeCode       InferenceType = "code"
	InferenceTypeReasoning  InferenceType = "reasoning"
	InferenceTypeAnalysis   InferenceType = "analysis"
	InferenceTypeSummary    InferenceType = "summary"
	InferenceTypeTranslate  InferenceType = "translate"
	InferenceTypeEmbedding  InferenceType = "embedding"
)

// InferenceStatus tracks request status
type InferenceStatus string

const (
	StatusPending    InferenceStatus = "pending"
	StatusProcessing InferenceStatus = "processing"
	StatusStreaming  InferenceStatus = "streaming"
	StatusCompleted  InferenceStatus = "completed"
	StatusFailed     InferenceStatus = "failed"
	StatusCancelled  InferenceStatus = "cancelled"
	StatusTimeout    InferenceStatus = "timeout"
)

// TokenUsage tracks detailed token usage
type TokenUsage struct {
	InputTokens     int `json:"input_tokens"`
	OutputTokens    int `json:"output_tokens"`
	TotalTokens     int `json:"total_tokens"`
	CachedTokens    int `json:"cached_tokens,omitempty"`
	ReasoningTokens int `json:"reasoning_tokens,omitempty"`
}

// ToolCall represents a function/tool call from the model
type ToolCall struct {
	ID       string                 `json:"id"`
	Type     string                 `json:"type"`
	Function *FunctionCall          `json:"function,omitempty"`
	Result   string                 `json:"result,omitempty"`
	Error    string                 `json:"error,omitempty"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// FunctionCall represents a function call
type FunctionCall struct {
	Name      string                 `json:"name"`
	Arguments map[string]interface{} `json:"arguments"`
}

// PerformanceStats tracks inference performance
type PerformanceStats struct {
	QueueTime       time.Duration `json:"queue_time"`
	ProcessingTime  time.Duration `json:"processing_time"`
	FirstTokenTime  time.Duration `json:"first_token_time"`
	TokensPerSecond float64       `json:"tokens_per_second"`
	MemoryUsed      int64         `json:"memory_used"`
	GPUUtilization  float64       `json:"gpu_utilization,omitempty"`
}

// OllamaRequest represents request to Ollama API
type OllamaRequest struct {
	Model    string                 `json:"model"`
	Messages []OllamaMessage        `json:"messages,omitempty"`
	Prompt   string                 `json:"prompt,omitempty"`
	Stream   bool                   `json:"stream"`
	Format   string                 `json:"format,omitempty"`
	Options  map[string]interface{} `json:"options,omitempty"`
	Template string                 `json:"template,omitempty"`
	Context  []int                  `json:"context,omitempty"`
	Raw      bool                   `json:"raw,omitempty"`
}

// OllamaMessage represents message format for Ollama
type OllamaMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// OllamaResponse represents response from Ollama
type OllamaResponse struct {
	Model              string         `json:"model"`
	CreatedAt          time.Time      `json:"created_at"`
	Message            *OllamaMessage `json:"message,omitempty"`
	Response           string         `json:"response,omitempty"`
	Done               bool           `json:"done"`
	Context            []int          `json:"context,omitempty"`
	TotalDuration      int64          `json:"total_duration,omitempty"`
	LoadDuration       int64          `json:"load_duration,omitempty"`
	PromptEvalCount    int            `json:"prompt_eval_count,omitempty"`
	PromptEvalDuration int64          `json:"prompt_eval_duration,omitempty"`
	EvalCount          int            `json:"eval_count,omitempty"`
	EvalDuration       int64          `json:"eval_duration,omitempty"`
}

// NewInferenceManager creates a new inference manager
func NewInferenceManager(
	configManager *ConfigManager,
	modelManager *ModelManager,
	tokenManager *TokenManager,
	memoryManager *MemoryManager,
	sessionManager *SessionManager,
	ollamaBaseURL string,
) *InferenceManager {
	return &InferenceManager{
		configManager:    configManager,
		modelManager:     modelManager,
		tokenManager:     tokenManager,
		memoryManager:    memoryManager,
		sessionManager:   sessionManager,
		activeInferences: make(map[string]*InferenceRequest),
		ollamaBaseURL:    ollamaBaseURL,
		client:           &http.Client{Timeout: 5 * time.Minute},
		requestTimeout:   5 * time.Minute,
		maxRetries:       3,
		retryDelay:       time.Second,
		shutdown:         make(chan struct{}),
	}
}

// ProcessInference handles a complete inference request
func (im *InferenceManager) ProcessInference(ctx context.Context, req *InferenceRequest) (*InferenceResult, error) {
	// Validate request
	if err := im.validateRequest(req); err != nil {
		return nil, fmt.Errorf("invalid request: %w", err)
	}

	// Check token budget
	if err := im.checkTokenBudget(req); err != nil {
		return nil, fmt.Errorf("token budget exceeded: %w", err)
	}

	// Select best model if not specified
	if req.ModelName == "" {
		modelName, err := im.selectBestModel(req)
		if err != nil {
			return nil, fmt.Errorf("model selection failed: %w", err)
		}
		req.ModelName = modelName
	}

	// Ensure model is loaded
	if err := im.ensureModelLoaded(ctx, req.ModelName); err != nil {
		return nil, fmt.Errorf("model loading failed: %w", err)
	}

	// Enhance messages with memory if requested
	if req.Parameters.UseMemory {
		if err := im.enhanceWithMemory(ctx, req); err != nil {
			log.Warn().Err(err).Msg("Failed to enhance with memory, continuing without")
		}
	}

	// Optimize context if requested
	if req.Parameters.ContextOptimize {
		if err := im.optimizeContext(req); err != nil {
			log.Warn().Err(err).Msg("Failed to optimize context, using original")
		}
	}

	// Register active inference
	im.registerInference(req)
	defer im.unregisterInference(req.ID)

	// Execute inference
	result, err := im.executeInference(ctx, req)
	if err != nil {
		req.Status = StatusFailed
		req.Error = err.Error()
		req.EndTime = time.Now()
		return nil, err
	}

	// Record usage statistics
	im.recordInferenceStats(req, result)

	// Store important interactions in memory
	if req.Parameters.UseMemory {
		im.storeInferenceMemory(ctx, req, result)
	}

	req.Status = StatusCompleted
	req.EndTime = time.Now()
	req.Result = result

	return result, nil
}

// ProcessStreamingInference handles streaming inference requests
func (im *InferenceManager) ProcessStreamingInference(ctx context.Context, req *InferenceRequest) (<-chan *StreamChunk, error) {
	// Validate and prepare request
	if err := im.validateRequest(req); err != nil {
		return nil, fmt.Errorf("invalid request: %w", err)
	}

	req.Parameters.Stream = true
	req.StreamChannel = make(chan *StreamChunk, 100)

	// Check token budget
	if err := im.checkTokenBudget(req); err != nil {
		return nil, fmt.Errorf("token budget exceeded: %w", err)
	}

	// Select and load model
	if req.ModelName == "" {
		modelName, err := im.selectBestModel(req)
		if err != nil {
			return nil, err
		}
		req.ModelName = modelName
	}

	if err := im.ensureModelLoaded(ctx, req.ModelName); err != nil {
		return nil, err
	}

	// Enhance with memory and optimize context
	if req.Parameters.UseMemory {
		im.enhanceWithMemory(ctx, req)
	}
	if req.Parameters.ContextOptimize {
		im.optimizeContext(req)
	}

	// Register and execute
	im.registerInference(req)

	// Start streaming in background
	go func() {
		defer func() {
			close(req.StreamChannel)
			im.unregisterInference(req.ID)
		}()

		if err := im.executeStreamingInference(ctx, req); err != nil {
			req.StreamChannel <- &StreamChunk{
				Error: err.Error(),
				Done:  true,
			}
		}
	}()

	return req.StreamChannel, nil
}

// executeInference performs the actual inference request to Ollama
func (im *InferenceManager) executeInference(ctx context.Context, req *InferenceRequest) (*InferenceResult, error) {
	req.Status = StatusProcessing
	startTime := time.Now()

	// Build Ollama request
	ollamaReq, err := im.buildOllamaRequest(req)
	if err != nil {
		return nil, fmt.Errorf("failed to build request: %w", err)
	}

	// Execute request
	ollamaResp, err := im.callOllama(ctx, ollamaReq)
	if err != nil {
		return nil, fmt.Errorf("ollama request failed: %w", err)
	}

	// Build result
	result := &InferenceResult{
		Content:         im.extractContent(ollamaResp),
		TokensGenerated: ollamaResp.EvalCount,
		TokensInput:     ollamaResp.PromptEvalCount,
		Duration:        time.Since(startTime),
		ModelUsed:       req.ModelName,
		FinishReason:    "stop", // TODO: Determine actual finish reason
		Usage: &TokenUsage{
			InputTokens:  ollamaResp.PromptEvalCount,
			OutputTokens: ollamaResp.EvalCount,
			TotalTokens:  ollamaResp.PromptEvalCount + ollamaResp.EvalCount,
		},
		PerformanceStats: &PerformanceStats{
			ProcessingTime:  time.Duration(ollamaResp.TotalDuration),
			FirstTokenTime:  time.Duration(ollamaResp.LoadDuration),
			TokensPerSecond: im.calculateTokensPerSecond(ollamaResp),
		},
	}

	return result, nil
}

// executeStreamingInference performs streaming inference
func (im *InferenceManager) executeStreamingInference(ctx context.Context, req *InferenceRequest) error {
	req.Status = StatusStreaming

	// Build Ollama request
	ollamaReq, err := im.buildOllamaRequest(req)
	if err != nil {
		return err
	}

	// Make streaming request
	return im.callOllamaStream(ctx, ollamaReq, req.StreamChannel)
}

// buildOllamaRequest converts our request to Ollama format
func (im *InferenceManager) buildOllamaRequest(req *InferenceRequest) (*OllamaRequest, error) {
	ollamaReq := &OllamaRequest{
		Model:   req.ModelName,
		Stream:  req.Parameters.Stream,
		Options: make(map[string]interface{}),
	}

	// Convert messages
	if len(req.Messages) > 0 {
		ollamaReq.Messages = make([]OllamaMessage, len(req.Messages))
		for i, msg := range req.Messages {
			ollamaReq.Messages[i] = OllamaMessage{
				Role:    msg.Role,
				Content: msg.Content,
			}
		}
	}

	// Set parameters
	if req.Parameters.Temperature > 0 {
		ollamaReq.Options["temperature"] = req.Parameters.Temperature
	}
	if req.Parameters.TopK > 0 {
		ollamaReq.Options["top_k"] = req.Parameters.TopK
	}
	if req.Parameters.TopP > 0 {
		ollamaReq.Options["top_p"] = req.Parameters.TopP
	}
	if req.Parameters.RepeatPenalty > 0 {
		ollamaReq.Options["repeat_penalty"] = req.Parameters.RepeatPenalty
	}
	if req.Parameters.MaxTokens > 0 {
		ollamaReq.Options["num_predict"] = req.Parameters.MaxTokens
	}
	if len(req.Parameters.Stop) > 0 {
		ollamaReq.Options["stop"] = req.Parameters.Stop
	}

	// Add custom options
	for k, v := range req.Parameters.CustomOptions {
		ollamaReq.Options[k] = v
	}

	return ollamaReq, nil
}

// callOllama makes a synchronous call to Ollama
func (im *InferenceManager) callOllama(ctx context.Context, req *OllamaRequest) (*OllamaResponse, error) {
	endpoint := "/api/chat"
	if req.Prompt != "" {
		endpoint = "/api/generate"
	}

	reqBody, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", im.ollamaBaseURL+endpoint, bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := im.client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("request failed with status %d", resp.StatusCode)
	}

	var ollamaResp OllamaResponse
	if err := json.NewDecoder(resp.Body).Decode(&ollamaResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &ollamaResp, nil
}

// callOllamaStream makes a streaming call to Ollama
func (im *InferenceManager) callOllamaStream(ctx context.Context, req *OllamaRequest, streamChan chan<- *StreamChunk) error {
	endpoint := "/api/chat"
	if req.Prompt != "" {
		endpoint = "/api/generate"
	}

	reqBody, err := json.Marshal(req)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", im.ollamaBaseURL+endpoint, bytes.NewBuffer(reqBody))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := im.client.Do(httpReq)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("request failed with status %d", resp.StatusCode)
	}

	// Stream responses
	decoder := json.NewDecoder(resp.Body)
	totalTokens := 0

	for {
		var ollamaResp OllamaResponse
		if err := decoder.Decode(&ollamaResp); err != nil {
			if err == io.EOF {
				break
			}
			return fmt.Errorf("failed to decode stream response: %w", err)
		}

		content := im.extractContent(&ollamaResp)
		totalTokens += len(strings.Fields(content))

		chunk := &StreamChunk{
			Content:    content,
			Done:       ollamaResp.Done,
			TokenCount: totalTokens,
		}

		select {
		case streamChan <- chunk:
		case <-ctx.Done():
			return ctx.Err()
		}

		if ollamaResp.Done {
			break
		}
	}

	return nil
}

// Helper functions

func (im *InferenceManager) validateRequest(req *InferenceRequest) error {
	if req == nil {
		return fmt.Errorf("request cannot be nil")
	}
	if req.UserID == "" {
		return fmt.Errorf("user ID is required")
	}
	if len(req.Messages) == 0 && req.Parameters.SystemPrompt == "" {
		return fmt.Errorf("messages or system prompt required")
	}
	return nil
}

func (im *InferenceManager) checkTokenBudget(req *InferenceRequest) error {
	// Estimate input tokens
	inputTokens := int64(0)
	for _, msg := range req.Messages {
		inputTokens += int64(im.tokenManager.EstimateTokens(msg.Content, req.ModelName))
	}

	tokenReq := &TokenUsageRequest{
		UserID:       req.UserID,
		SessionID:    req.SessionID,
		ModelName:    req.ModelName,
		InputTokens:  inputTokens,
		OutputTokens: int64(req.Parameters.MaxTokens),
	}

	tokenResp, err := im.tokenManager.CheckTokenUsage(tokenReq)
	if err != nil {
		return err
	}

	if !tokenResp.Allowed {
		return fmt.Errorf("token usage not allowed: %s", tokenResp.BlockReason)
	}

	return nil
}

func (im *InferenceManager) selectBestModel(req *InferenceRequest) (string, error) {
	// Determine specialization based on request type
	specialization := ""
	switch req.RequestType {
	case InferenceTypeCode:
		specialization = "code"
	case InferenceTypeReasoning:
		specialization = "reasoning"
	case InferenceTypeAnalysis:
		specialization = "analysis"
	default:
		specialization = "chat"
	}

	return im.modelManager.GetBestModel(specialization)
}

func (im *InferenceManager) ensureModelLoaded(ctx context.Context, modelName string) error {
	return im.modelManager.LoadModel(ctx, modelName)
}

func (im *InferenceManager) enhanceWithMemory(ctx context.Context, req *InferenceRequest) error {
	if req.SessionID == "" {
		return nil // No session, no memory enhancement
	}

	// Get relevant memories
	memoryQuery := &MemoryQuery{
		UserID:              req.UserID,
		Content:             im.extractQueryContent(req.Messages),
		Limit:               req.Parameters.MemoryDepth,
		SimilarityThreshold: 0.7,
		MaxAge:              24 * time.Hour, // Recent memories are more relevant
	}

	memories, err := im.memoryManager.RetrieveMemories(ctx, memoryQuery)
	if err != nil {
		return err
	}

	// Add memory context as system message
	if len(memories) > 0 {
		memoryContent := im.buildMemoryContext(memories)
		memoryMsg := Message{
			Role:    "system",
			Content: fmt.Sprintf("Relevant context from past conversations:\n%s", memoryContent),
		}

		// Insert after existing system messages but before user messages
		req.Messages = im.insertMemoryMessage(req.Messages, memoryMsg)
	}

	return nil
}

func (im *InferenceManager) optimizeContext(req *InferenceRequest) error {
	maxTokens := 4096 // Default context window
	if config, err := im.configManager.GetModelConfig(req.ModelName); err == nil {
		maxTokens = config.ContextWindow
	}

	optimized, _, err := im.tokenManager.OptimizeContext(req.Messages, maxTokens, req.ModelName)
	if err != nil {
		return err
	}

	req.Messages = optimized
	return nil
}

func (im *InferenceManager) registerInference(req *InferenceRequest) {
	im.mu.Lock()
	defer im.mu.Unlock()

	req.StartTime = time.Now()
	req.Status = StatusPending
	im.activeInferences[req.ID] = req
}

func (im *InferenceManager) unregisterInference(reqID string) {
	im.mu.Lock()
	defer im.mu.Unlock()

	delete(im.activeInferences, reqID)
}

func (im *InferenceManager) recordInferenceStats(req *InferenceRequest, result *InferenceResult) {
	// Record in model manager
	im.modelManager.RecordModelUsage(
		req.ModelName,
		int64(result.Usage.TotalTokens),
		result.Duration,
		nil,
	)

	// Record token usage
	tokenReq := &TokenUsageRequest{
		UserID:       req.UserID,
		SessionID:    req.SessionID,
		ModelName:    req.ModelName,
		InputTokens:  int64(result.Usage.InputTokens),
		OutputTokens: int64(result.Usage.OutputTokens),
	}

	im.tokenManager.CheckTokenUsage(tokenReq) // This records the usage
}

func (im *InferenceManager) storeInferenceMemory(ctx context.Context, req *InferenceRequest, result *InferenceResult) {
	// Store user message
	if len(req.Messages) > 0 {
		lastUserMsg := req.Messages[len(req.Messages)-1]
		if lastUserMsg.Role == "user" {
			memory := &Memory{
				UserID:     req.UserID,
				SessionID:  req.SessionID,
				Content:    lastUserMsg.Content,
				MemoryType: MemoryTypeConversation,
				Source:     SourceChat,
				Importance: 0.5, // Will be calculated by memory manager
			}
			im.memoryManager.StoreMemory(ctx, memory)
		}
	}

	// Store assistant response
	assistantMemory := &Memory{
		UserID:     req.UserID,
		SessionID:  req.SessionID,
		Content:    result.Content,
		MemoryType: MemoryTypeConversation,
		Source:     SourceChat,
		Importance: 0.4,
	}
	im.memoryManager.StoreMemory(ctx, assistantMemory)
}

func (im *InferenceManager) extractContent(resp *OllamaResponse) string {
	if resp.Message != nil {
		return resp.Message.Content
	}
	return resp.Response
}

func (im *InferenceManager) extractQueryContent(messages []Message) string {
	// Extract content from user messages for memory search
	var content []string
	for _, msg := range messages {
		if msg.Role == "user" {
			content = append(content, msg.Content)
		}
	}
	return strings.Join(content, " ")
}

func (im *InferenceManager) buildMemoryContext(memories []*MemoryResult) string {
	var context []string
	for _, result := range memories {
		context = append(context, fmt.Sprintf("- %s", result.Memory.Summary))
	}
	return strings.Join(context, "\n")
}

func (im *InferenceManager) insertMemoryMessage(messages []Message, memoryMsg Message) []Message {
	// Insert memory message after system messages but before user messages
	insertIndex := 0
	for i, msg := range messages {
		if msg.Role != "system" {
			insertIndex = i
			break
		}
	}

	result := make([]Message, 0, len(messages)+1)
	result = append(result, messages[:insertIndex]...)
	result = append(result, memoryMsg)
	result = append(result, messages[insertIndex:]...)

	return result
}

func (im *InferenceManager) calculateTokensPerSecond(resp *OllamaResponse) float64 {
	if resp.EvalDuration == 0 {
		return 0
	}
	duration := time.Duration(resp.EvalDuration)
	return float64(resp.EvalCount) / duration.Seconds()
}

// GetActiveInferences returns currently active inference requests
func (im *InferenceManager) GetActiveInferences() map[string]*InferenceRequest {
	im.mu.RLock()
	defer im.mu.RUnlock()

	result := make(map[string]*InferenceRequest)
	for k, v := range im.activeInferences {
		result[k] = v
	}
	return result
}

// CancelInference cancels an active inference request
func (im *InferenceManager) CancelInference(requestID string) error {
	im.mu.Lock()
	defer im.mu.Unlock()

	req, exists := im.activeInferences[requestID]
	if !exists {
		return fmt.Errorf("inference request not found: %s", requestID)
	}

	if req.CancelFunc != nil {
		req.CancelFunc()
	}

	req.Status = StatusCancelled
	req.EndTime = time.Now()

	return nil
}

// Shutdown gracefully shuts down the inference manager
func (im *InferenceManager) Shutdown(ctx context.Context) error {
	log.Info().Msg("Shutting down inference manager")

	// Cancel all active inferences
	im.mu.Lock()
	for _, req := range im.activeInferences {
		if req.CancelFunc != nil {
			req.CancelFunc()
		}
	}
	im.mu.Unlock()

	close(im.shutdown)
	log.Info().Msg("Inference manager shutdown complete")
	return nil
}
