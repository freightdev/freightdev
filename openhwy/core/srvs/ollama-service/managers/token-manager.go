// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = managers/token-manager.go

package managers

import (
	// stdlib
	"context"
	"fmt"
	"math"
	"sync"
	"time"

	// third-party
	"github.com/rs/zerolog/log"

	// internal
)

// TokenManager provides complete token control and optimization
type TokenManager struct {
	mu               sync.RWMutex
	userBudgets      map[string]*UserTokenBudget
	rateLimiters     map[string]*RateLimiter
	tokenCounters    map[string]*TokenCounter
	contextOptimizer *ContextOptimizer
	configManager    *ConfigManager
	resetTicker      *time.Ticker
	shutdown         chan struct{}
}

// UserTokenBudget tracks token budget per user
type UserTokenBudget struct {
	UserID           string    `json:"user_id"`
	TotalBudget      int64     `json:"total_budget"`
	UsedTokens       int64     `json:"used_tokens"`
	RemainingTokens  int64     `json:"remaining_tokens"`
	ResetAt          time.Time `json:"reset_at"`
	DailyLimit       int64     `json:"daily_limit"`
	HourlyLimit      int64     `json:"hourly_limit"`
	MonthlyLimit     int64     `json:"monthly_limit"`
	IsUnlimited      bool      `json:"is_unlimited"`
	OverageAllowed   bool      `json:"overage_allowed"`
	WarningThreshold float64   `json:"warning_threshold"` // 0.0-1.0
	LastWarningAt    time.Time `json:"last_warning_at"`
}

// TokenCounter tracks detailed token usage statistics
type TokenCounter struct {
	UserID       string                   `json:"user_id"`
	TotalTokens  int64                    `json:"total_tokens"`
	InputTokens  int64                    `json:"input_tokens"`
	OutputTokens int64                    `json:"output_tokens"`
	CachedTokens int64                    `json:"cached_tokens"`
	ModelUsage   map[string]*ModelUsage   `json:"model_usage"`
	HourlyStats  map[string]int64         `json:"hourly_stats"`
	DailyStats   map[string]int64         `json:"daily_stats"`
	SessionStats map[string]*SessionUsage `json:"session_stats"`
	LastReset    time.Time                `json:"last_reset"`
	CreatedAt    time.Time                `json:"created_at"`
}

// ModelUsage tracks usage per model
type ModelUsage struct {
	ModelName      string        `json:"model_name"`
	RequestCount   int64         `json:"request_count"`
	TotalTokens    int64         `json:"total_tokens"`
	InputTokens    int64         `json:"input_tokens"`
	OutputTokens   int64         `json:"output_tokens"`
	AverageLatency time.Duration `json:"average_latency"`
	ErrorCount     int64         `json:"error_count"`
	LastUsed       time.Time     `json:"last_used"`
}

// SessionUsage tracks usage per session
type SessionUsage struct {
	SessionID    string    `json:"session_id"`
	TokensUsed   int64     `json:"tokens_used"`
	MessageCount int       `json:"message_count"`
	StartTime    time.Time `json:"start_time"`
	EndTime      time.Time `json:"end_time"`
	ModelUsed    string    `json:"model_used"`
}

// RateLimiter controls request rate limiting
type RateLimiter struct {
	UserID         string                 `json:"user_id"`
	RequestsPerMin int                    `json:"requests_per_min"`
	TokensPerMin   int64                  `json:"tokens_per_min"`
	RequestCount   int                    `json:"request_count"`
	TokenCount     int64                  `json:"token_count"`
	WindowStart    time.Time              `json:"window_start"`
	ViolationCount int                    `json:"violation_count"`
	LastViolation  time.Time              `json:"last_violation"`
	IsBlocked      bool                   `json:"is_blocked"`
	BlockedUntil   time.Time              `json:"blocked_until"`
	CustomLimits   map[string]interface{} `json:"custom_limits"`
}

// ContextOptimizer optimizes token usage in conversations
type ContextOptimizer struct {
	mu               sync.RWMutex
	compressionRules map[string]*CompressionRule
	summaryCache     map[string]*ContextSummary
	tokenEstimator   *TokenEstimator
}

// CompressionRule defines how to compress different types of content
type CompressionRule struct {
	ContentType      string        `json:"content_type"`
	MinAge           time.Duration `json:"min_age"`
	CompressionRatio float64       `json:"compression_ratio"`
	PreserveRecent   int           `json:"preserve_recent"`
	SummaryTemplate  string        `json:"summary_template"`
	Importance       float64       `json:"importance"`
}

// ContextSummary holds compressed context
type ContextSummary struct {
	OriginalTokens   int                    `json:"original_tokens"`
	CompressedTokens int                    `json:"compressed_tokens"`
	Summary          string                 `json:"summary"`
	CreatedAt        time.Time              `json:"created_at"`
	KeyPoints        []string               `json:"key_points"`
	Metadata         map[string]interface{} `json:"metadata"`
}

// TokenEstimator provides accurate token counting
type TokenEstimator struct {
	mu            sync.RWMutex
	modelEncoders map[string]*ModelEncoder
	fallbackRatio float64 // chars per token for unknown models
}

// ModelEncoder handles model-specific token encoding
type ModelEncoder struct {
	ModelName     string  `json:"model_name"`
	CharsPerToken float64 `json:"chars_per_token"`
	Overhead      int     `json:"overhead"` // Additional tokens per message
	MaxTokens     int     `json:"max_tokens"`
}

// TokenUsageRequest represents a token usage request
type TokenUsageRequest struct {
	UserID       string `json:"user_id"`
	SessionID    string `json:"session_id,omitempty"`
	ModelName    string `json:"model_name"`
	InputTokens  int64  `json:"input_tokens"`
	OutputTokens int64  `json:"output_tokens,omitempty"`
	Cached       bool   `json:"cached,omitempty"`
}

// TokenUsageResponse contains the response to a token usage request
type TokenUsageResponse struct {
	Allowed         bool      `json:"allowed"`
	RemainingTokens int64     `json:"remaining_tokens"`
	UsedTokens      int64     `json:"used_tokens"`
	ResetAt         time.Time `json:"reset_at"`
	WarningMessage  string    `json:"warning_message,omitempty"`
	BlockReason     string    `json:"block_reason,omitempty"`
}

// NewTokenManager creates a new token manager
func NewTokenManager(configManager *ConfigManager) *TokenManager {
	tm := &TokenManager{
		userBudgets:      make(map[string]*UserTokenBudget),
		rateLimiters:     make(map[string]*RateLimiter),
		tokenCounters:    make(map[string]*TokenCounter),
		contextOptimizer: NewContextOptimizer(),
		configManager:    configManager,
		shutdown:         make(chan struct{}),
	}

	// Start periodic reset
	tm.resetTicker = time.NewTicker(time.Hour)
	go tm.runPeriodicReset()

	return tm
}

// CheckTokenUsage checks if a token usage request is allowed
func (tm *TokenManager) CheckTokenUsage(req *TokenUsageRequest) (*TokenUsageResponse, error) {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	// Get or create user budget
	budget := tm.getUserBudget(req.UserID)
	rateLimiter := tm.getRateLimiter(req.UserID)

	// Check rate limits first
	if !tm.checkRateLimit(rateLimiter, req.InputTokens) {
		return &TokenUsageResponse{
			Allowed:     false,
			BlockReason: "Rate limit exceeded",
		}, nil
	}

	totalTokens := req.InputTokens + req.OutputTokens

	// Check if user has unlimited access
	if budget.IsUnlimited {
		tm.recordUsage(req, totalTokens)
		return &TokenUsageResponse{
			Allowed:         true,
			RemainingTokens: -1, // Unlimited
			UsedTokens:      budget.UsedTokens,
		}, nil
	}

	// Check budget limits
	if budget.UsedTokens+totalTokens > budget.TotalBudget {
		if !budget.OverageAllowed {
			return &TokenUsageResponse{
				Allowed:         false,
				BlockReason:     "Token budget exceeded",
				RemainingTokens: budget.RemainingTokens,
			}, nil
		}
	}

	// Check warning threshold
	warningMsg := ""
	usageRatio := float64(budget.UsedTokens+totalTokens) / float64(budget.TotalBudget)
	if usageRatio >= budget.WarningThreshold && time.Since(budget.LastWarningAt) > time.Hour {
		warningMsg = fmt.Sprintf("Warning: %.1f%% of token budget used", usageRatio*100)
		budget.LastWarningAt = time.Now()
	}

	// Record usage
	tm.recordUsage(req, totalTokens)
	budget.UsedTokens += totalTokens
	budget.RemainingTokens = budget.TotalBudget - budget.UsedTokens

	return &TokenUsageResponse{
		Allowed:         true,
		RemainingTokens: budget.RemainingTokens,
		UsedTokens:      budget.UsedTokens,
		ResetAt:         budget.ResetAt,
		WarningMessage:  warningMsg,
	}, nil
}

// EstimateTokens estimates token count for given text and model
func (tm *TokenManager) EstimateTokens(text, modelName string) int {
	return tm.contextOptimizer.tokenEstimator.EstimateTokens(text, modelName)
}

// OptimizeContext optimizes context to fit within token limits
func (tm *TokenManager) OptimizeContext(messages []Message, maxTokens int, modelName string) ([]Message, *ContextSummary, error) {
	return tm.contextOptimizer.OptimizeContext(messages, maxTokens, modelName)
}

// GetUserUsage returns detailed usage statistics for a user
func (tm *TokenManager) GetUserUsage(userID string) (*TokenCounter, *UserTokenBudget, error) {
	tm.mu.RLock()
	defer tm.mu.RUnlock()

	counter, exists := tm.tokenCounters[userID]
	if !exists {
		return nil, nil, fmt.Errorf("user not found: %s", userID)
	}

	budget := tm.getUserBudget(userID)
	return counter, budget, nil
}

// SetUserBudget sets token budget for a user
func (tm *TokenManager) SetUserBudget(userID string, budget *UserTokenBudget) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	budget.UserID = userID
	budget.RemainingTokens = budget.TotalBudget - budget.UsedTokens
	if budget.ResetAt.IsZero() {
		budget.ResetAt = time.Now().Add(24 * time.Hour)
	}

	tm.userBudgets[userID] = budget

	log.Info().
		Str("user_id", userID).
		Int64("total_budget", budget.TotalBudget).
		Msg("Set user token budget")

	return nil
}

// ResetUserBudget resets token budget for a user
func (tm *TokenManager) ResetUserBudget(userID string) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	budget := tm.getUserBudget(userID)
	budget.UsedTokens = 0
	budget.RemainingTokens = budget.TotalBudget
	budget.ResetAt = time.Now().Add(24 * time.Hour)

	// Reset rate limiter
	if rateLimiter, exists := tm.rateLimiters[userID]; exists {
		rateLimiter.RequestCount = 0
		rateLimiter.TokenCount = 0
		rateLimiter.WindowStart = time.Now()
		rateLimiter.IsBlocked = false
	}

	log.Info().Str("user_id", userID).Msg("Reset user token budget")
	return nil
}

// Helper functions

func (tm *TokenManager) getUserBudget(userID string) *UserTokenBudget {
	budget, exists := tm.userBudgets[userID]
	if !exists {
		// Create default budget from config
		limitsConfig, _ := tm.configManager.GetLimitsConfig()
		budget = &UserTokenBudget{
			UserID:           userID,
			TotalBudget:      limitsConfig.TokenBudgetPerUser,
			UsedTokens:       0,
			RemainingTokens:  limitsConfig.TokenBudgetPerUser,
			ResetAt:          time.Now().Add(time.Duration(limitsConfig.ResetIntervalHours) * time.Hour),
			DailyLimit:       limitsConfig.TokenBudgetPerUser,
			HourlyLimit:      limitsConfig.TokenBudgetPerUser / 24,
			IsUnlimited:      false,
			OverageAllowed:   false,
			WarningThreshold: 0.8,
		}
		tm.userBudgets[userID] = budget
	}
	return budget
}

func (tm *TokenManager) getRateLimiter(userID string) *RateLimiter {
	limiter, exists := tm.rateLimiters[userID]
	if !exists {
		limitsConfig, _ := tm.configManager.GetLimitsConfig()
		limiter = &RateLimiter{
			UserID:         userID,
			RequestsPerMin: limitsConfig.MaxRequestsPerMinute,
			TokensPerMin:   int64(limitsConfig.MaxTokensPerRequest * limitsConfig.MaxRequestsPerMinute),
			WindowStart:    time.Now(),
			CustomLimits:   make(map[string]interface{}),
		}
		tm.rateLimiters[userID] = limiter
	}
	return limiter
}

func (tm *TokenManager) checkRateLimit(limiter *RateLimiter, tokens int64) bool {
	now := time.Now()

	// Reset window if needed
	if now.Sub(limiter.WindowStart) >= time.Minute {
		limiter.RequestCount = 0
		limiter.TokenCount = 0
		limiter.WindowStart = now
	}

	// Check if blocked
	if limiter.IsBlocked && now.Before(limiter.BlockedUntil) {
		return false
	}
	limiter.IsBlocked = false

	// Check limits
	if limiter.RequestCount >= limiter.RequestsPerMin || limiter.TokenCount+tokens > limiter.TokensPerMin {
		limiter.ViolationCount++
		limiter.LastViolation = now

		// Block for repeated violations
		if limiter.ViolationCount >= 3 {
			limiter.IsBlocked = true
			limiter.BlockedUntil = now.Add(time.Minute * time.Duration(limiter.ViolationCount))
		}

		return false
	}

	limiter.RequestCount++
	limiter.TokenCount += tokens
	return true
}

func (tm *TokenManager) recordUsage(req *TokenUsageRequest, totalTokens int64) {
	counter, exists := tm.tokenCounters[req.UserID]
	if !exists {
		counter = &TokenCounter{
			UserID:       req.UserID,
			ModelUsage:   make(map[string]*ModelUsage),
			HourlyStats:  make(map[string]int64),
			DailyStats:   make(map[string]int64),
			SessionStats: make(map[string]*SessionUsage),
			CreatedAt:    time.Now(),
		}
		tm.tokenCounters[req.UserID] = counter
	}

	counter.TotalTokens += totalTokens
	counter.InputTokens += req.InputTokens
	counter.OutputTokens += req.OutputTokens

	if req.Cached {
		counter.CachedTokens += req.InputTokens
	}

	// Record model usage
	modelUsage, exists := counter.ModelUsage[req.ModelName]
	if !exists {
		modelUsage = &ModelUsage{
			ModelName: req.ModelName,
		}
		counter.ModelUsage[req.ModelName] = modelUsage
	}

	modelUsage.RequestCount++
	modelUsage.TotalTokens += totalTokens
	modelUsage.InputTokens += req.InputTokens
	modelUsage.OutputTokens += req.OutputTokens
	modelUsage.LastUsed = time.Now()

	// Record session usage if provided
	if req.SessionID != "" {
		sessionUsage, exists := counter.SessionStats[req.SessionID]
		if !exists {
			sessionUsage = &SessionUsage{
				SessionID: req.SessionID,
				StartTime: time.Now(),
				ModelUsed: req.ModelName,
			}
			counter.SessionStats[req.SessionID] = sessionUsage
		}
		sessionUsage.TokensUsed += totalTokens
		sessionUsage.MessageCount++
		sessionUsage.EndTime = time.Now()
	}

	// Update hourly/daily stats
	hour := time.Now().Format("2006-01-02-15")
	day := time.Now().Format("2006-01-02")
	counter.HourlyStats[hour] += totalTokens
	counter.DailyStats[day] += totalTokens
}

func (tm *TokenManager) runPeriodicReset() {
	for {
		select {
		case <-tm.resetTicker.C:
			tm.checkResets()
		case <-tm.shutdown:
			tm.resetTicker.Stop()
			return
		}
	}
}

func (tm *TokenManager) checkResets() {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	now := time.Now()
	for userID, budget := range tm.userBudgets {
		if now.After(budget.ResetAt) {
			tm.ResetUserBudget(userID)
		}
	}
}

// Context Optimizer implementation

func NewContextOptimizer() *ContextOptimizer {
	return &ContextOptimizer{
		compressionRules: make(map[string]*CompressionRule),
		summaryCache:     make(map[string]*ContextSummary),
		tokenEstimator:   NewTokenEstimator(),
	}
}

func (co *ContextOptimizer) OptimizeContext(messages []Message, maxTokens int, modelName string) ([]Message, *ContextSummary, error) {
	currentTokens := co.tokenEstimator.EstimateMessagesTokens(messages, modelName)

	if currentTokens <= maxTokens {
		return messages, nil, nil
	}

	// Find messages to compress
	compressibleMessages := make([]Message, 0)
	recentMessages := make([]Message, 0)

	// Keep recent messages, compress older ones
	recentCount := len(messages) / 4 // Keep 25% of recent messages
	if recentCount < 5 {
		recentCount = 5
	}

	if len(messages) > recentCount {
		compressibleMessages = messages[:len(messages)-recentCount]
		recentMessages = messages[len(messages)-recentCount:]
	} else {
		recentMessages = messages
	}

	// Create summary of compressible messages
	summary := co.createSummary(compressibleMessages, modelName)

	// Create system message with summary
	summaryMessage := Message{
		ID:        "summary",
		Role:      "system",
		Content:   fmt.Sprintf("Previous conversation summary: %s", summary.Summary),
		Timestamp: time.Now(),
		Tokens:    summary.CompressedTokens,
	}

	optimizedMessages := append([]Message{summaryMessage}, recentMessages...)

	return optimizedMessages, summary, nil
}

func (co *ContextOptimizer) createSummary(messages []Message, modelName string) *ContextSummary {
	// Simple summarization - in practice, you'd use a model to create better summaries
	var totalContent string
	originalTokens := 0

	for _, msg := range messages {
		totalContent += fmt.Sprintf("%s: %s\n", msg.Role, msg.Content)
		originalTokens += msg.Tokens
	}

	// Create a simple summary (truncate to 1/4 of original)
	summaryLength := len(totalContent) / 4
	if summaryLength > len(totalContent) {
		summaryLength = len(totalContent)
	}

	summary := totalContent[:summaryLength] + "..."
	compressedTokens := co.tokenEstimator.EstimateTokens(summary, modelName)

	return &ContextSummary{
		OriginalTokens:   originalTokens,
		CompressedTokens: compressedTokens,
		Summary:          summary,
		CreatedAt:        time.Now(),
		KeyPoints:        []string{}, // TODO: Extract key points
	}
}

// Token Estimator implementation

func NewTokenEstimator() *TokenEstimator {
	te := &TokenEstimator{
		modelEncoders: make(map[string]*ModelEncoder),
		fallbackRatio: 4.0, // 4 chars per token average
	}

	// Add common model encoders
	te.modelEncoders["llama3.2"] = &ModelEncoder{
		ModelName:     "llama3.2",
		CharsPerToken: 3.8,
		Overhead:      5,
		MaxTokens:     8192,
	}
	te.modelEncoders["codellama"] = &ModelEncoder{
		ModelName:     "codellama",
		CharsPerToken: 4.2,
		Overhead:      3,
		MaxTokens:     4096,
	}

	return te
}

func (te *TokenEstimator) EstimateTokens(text, modelName string) int {
	te.mu.RLock()
	defer te.mu.RUnlock()

	encoder, exists := te.modelEncoders[modelName]
	if !exists {
		return int(math.Ceil(float64(len(text)) / te.fallbackRatio))
	}

	return int(math.Ceil(float64(len(text))/encoder.CharsPerToken)) + encoder.Overhead
}

func (te *TokenEstimator) EstimateMessagesTokens(messages []Message, modelName string) int {
	total := 0
	for _, msg := range messages {
		if msg.Tokens > 0 {
			total += msg.Tokens
		} else {
			total += te.EstimateTokens(msg.Content, modelName)
		}
	}
	return total
}

// Shutdown gracefully shuts down the token manager
func (tm *TokenManager) Shutdown(ctx context.Context) error {
	log.Info().Msg("Shutting down token manager")
	close(tm.shutdown)
	log.Info().Msg("Token manager shutdown complete")
	return nil
}
