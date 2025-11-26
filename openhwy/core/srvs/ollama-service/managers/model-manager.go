// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = managers/model-manager.go

package managers

import (
	// stdlib
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"runtime"
	"sync"
	"time"

	"github.com/rs/zerolog/log"
	// third-party
)

// ModelManager handles all model operations and lifecycle
type ModelManager struct {
	mu            sync.RWMutex
	ollamaBaseURL string
	client        *http.Client
	loadedModels  map[string]*ModelInfo
	modelStats    map[string]*ModelStats
	configManager *ConfigManager
	memoryMonitor *MemoryMonitor
	loadQueue     chan *ModelLoadRequest
	shutdown      chan struct{}
}

// ModelInfo represents loaded model information
type ModelInfo struct {
	Name           string            `json:"name"`
	Size           int64             `json:"size"`
	LoadedAt       time.Time         `json:"loaded_at"`
	LastUsed       time.Time         `json:"last_used"`
	Config         *ModelConfig      `json:"config"`
	Specialization string            `json:"specialization"`
	Priority       int               `json:"priority"`
	Status         string            `json:"status"` // loading, loaded, error, unloading
	ErrorMsg       string            `json:"error_msg,omitempty"`
	Parameters     map[string]string `json:"parameters"`
}

// ModelStats tracks model usage statistics
type ModelStats struct {
	RequestCount     int64         `json:"request_count"`
	TotalTokens      int64         `json:"total_tokens"`
	AverageLatency   time.Duration `json:"average_latency"`
	ErrorCount       int64         `json:"error_count"`
	LastError        string        `json:"last_error,omitempty"`
	LastErrorAt      time.Time     `json:"last_error_at,omitempty"`
	ThroughputPerSec float64       `json:"throughput_per_sec"`
}

// ModelLoadRequest represents a request to load a model
type ModelLoadRequest struct {
	ModelName    string
	Priority     int
	ResponseChan chan error
}

// OllamaListResponse represents Ollama's /api/tags response
type OllamaListResponse struct {
	Models []struct {
		Name       string    `json:"name"`
		Size       int64     `json:"size"`
		ModifiedAt time.Time `json:"modified_at"`
	} `json:"models"`
}

// OllamaGenerateRequest represents Ollama's generate request
type OllamaGenerateRequest struct {
	Model     string                 `json:"model"`
	Prompt    string                 `json:"prompt,omitempty"`
	Messages  []map[string]string    `json:"messages,omitempty"`
	Stream    bool                   `json:"stream"`
	Options   map[string]interface{} `json:"options,omitempty"`
	KeepAlive string                 `json:"keep_alive,omitempty"`
}

// MemoryMonitor tracks system memory usage
type MemoryMonitor struct {
	mu sync.RWMutex
}

// MemoryStats holds memory usage metrics
type MemoryStats struct {
	TotalRAM  uint64 `json:"total_ram"`
	UsedRAM   uint64 `json:"used_ram"`
	FreeRAM   uint64 `json:"free_ram"`
	TotalVRAM uint64 `json:"total_vram"`
	UsedVRAM  uint64 `json:"used_vram"`
}

// NewModelManager creates a new model manager
func NewModelManager(ollamaBaseURL string, configManager *ConfigManager) *ModelManager {
	mm := &ModelManager{
		ollamaBaseURL: ollamaBaseURL,
		client:        &http.Client{Timeout: 300 * time.Second}, // Extended timeout for model loading
		loadedModels:  make(map[string]*ModelInfo),
		modelStats:    make(map[string]*ModelStats),
		configManager: configManager,
		memoryMonitor: &MemoryMonitor{},
		loadQueue:     make(chan *ModelLoadRequest, 100),
		shutdown:      make(chan struct{}),
	}

	// Start background workers
	go mm.processLoadQueue()
	go mm.monitorModels()

	return mm
}

// Initialize loads startup models and validates configuration
func (mm *ModelManager) Initialize(ctx context.Context) error {
	log.Info().Msg("Initializing model manager")

	// Validate Ollama connection
	if err := mm.pingOllama(ctx); err != nil {
		return fmt.Errorf("failed to connect to Ollama: %w", err)
	}

	// Get available models from Ollama
	availableModels, err := mm.listAvailableModels(ctx)
	if err != nil {
		return fmt.Errorf("failed to list available models: %w", err)
	}

	log.Info().Int("available_models", len(availableModels.Models)).Msg("Found available models")

	// Load startup models
	modelConfigs, err := mm.configManager.GetModelConfigs()
	if err != nil {
		return fmt.Errorf("failed to get model configs: %w", err)
	}

	for _, config := range modelConfigs {
		if config.LoadOnStartup {
			log.Info().Str("model", config.Name).Msg("Loading startup model")
			if err := mm.LoadModel(ctx, config.Name); err != nil {
				log.Error().Err(err).Str("model", config.Name).Msg("Failed to load startup model")
			}
		}
	}

	log.Info().Msg("Model manager initialized successfully")
	return nil
}

// LoadModel loads a model into memory
func (mm *ModelManager) LoadModel(ctx context.Context, modelName string) error {
	mm.mu.Lock()
	defer mm.mu.Unlock()

	// Check if already loaded
	if info, exists := mm.loadedModels[modelName]; exists {
		if info.Status == "loaded" {
			info.LastUsed = time.Now()
			return nil
		}
	}

	// Get model configuration
	modelConfig, err := mm.configManager.GetModelConfig(modelName)
	if err != nil {
		return fmt.Errorf("model config not found: %w", err)
	}

	// Create model info
	modelInfo := &ModelInfo{
		Name:           modelName,
		LoadedAt:       time.Now(),
		LastUsed:       time.Now(),
		Config:         modelConfig,
		Specialization: modelConfig.Specialization,
		Priority:       modelConfig.Priority,
		Status:         "loading",
		Parameters:     modelConfig.Parameters,
	}

	mm.loadedModels[modelName] = modelInfo

	// Initialize stats if not exists
	if _, exists := mm.modelStats[modelName]; !exists {
		mm.modelStats[modelName] = &ModelStats{}
	}

	// Send load request to Ollama
	req := &OllamaGenerateRequest{
		Model:     modelName,
		Prompt:    "Hello", // Simple prompt to load model
		Stream:    false,
		KeepAlive: "5m", // Keep model loaded for 5 minutes
	}

	reqBody, err := json.Marshal(req)
	if err != nil {
		modelInfo.Status = "error"
		modelInfo.ErrorMsg = fmt.Sprintf("failed to marshal request: %v", err)
		return fmt.Errorf("failed to marshal load request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", mm.ollamaBaseURL+"/api/generate", bytes.NewBuffer(reqBody))
	if err != nil {
		modelInfo.Status = "error"
		modelInfo.ErrorMsg = fmt.Sprintf("failed to create request: %v", err)
		return fmt.Errorf("failed to create load request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := mm.client.Do(httpReq)
	if err != nil {
		modelInfo.Status = "error"
		modelInfo.ErrorMsg = fmt.Sprintf("failed to load model: %v", err)
		return fmt.Errorf("failed to load model: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		modelInfo.Status = "error"
		modelInfo.ErrorMsg = fmt.Sprintf("load request failed with status: %d", resp.StatusCode)
		return fmt.Errorf("load request failed with status: %d", resp.StatusCode)
	}

	modelInfo.Status = "loaded"
	log.Info().Str("model", modelName).Msg("Model loaded successfully")

	return nil
}

// UnloadModel unloads a model from memory
func (mm *ModelManager) UnloadModel(ctx context.Context, modelName string) error {
	mm.mu.Lock()
	defer mm.mu.Unlock()

	modelInfo, exists := mm.loadedModels[modelName]
	if !exists {
		return fmt.Errorf("model not loaded: %s", modelName)
	}

	modelInfo.Status = "unloading"

	// Send unload request to Ollama (set keep_alive to 0)
	req := &OllamaGenerateRequest{
		Model:     modelName,
		KeepAlive: "0",
	}

	reqBody, err := json.Marshal(req)
	if err != nil {
		return fmt.Errorf("failed to marshal unload request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST", mm.ollamaBaseURL+"/api/generate", bytes.NewBuffer(reqBody))
	if err != nil {
		return fmt.Errorf("failed to create unload request: %w", err)
	}

	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := mm.client.Do(httpReq)
	if err != nil {
		return fmt.Errorf("failed to unload model: %w", err)
	}
	defer resp.Body.Close()

	delete(mm.loadedModels, modelName)
	log.Info().Str("model", modelName).Msg("Model unloaded successfully")

	return nil
}

// GetLoadedModels returns all currently loaded models
func (mm *ModelManager) GetLoadedModels() map[string]*ModelInfo {
	mm.mu.RLock()
	defer mm.mu.RUnlock()

	// Return a copy to avoid race conditions
	result := make(map[string]*ModelInfo)
	for k, v := range mm.loadedModels {
		result[k] = v
	}
	return result
}

// GetModelInfo returns information about a specific model
func (mm *ModelManager) GetModelInfo(modelName string) (*ModelInfo, bool) {
	mm.mu.RLock()
	defer mm.mu.RUnlock()

	info, exists := mm.loadedModels[modelName]
	return info, exists
}

// GetModelStats returns statistics for a model
func (mm *ModelManager) GetModelStats(modelName string) (*ModelStats, bool) {
	mm.mu.RLock()
	defer mm.mu.RUnlock()

	stats, exists := mm.modelStats[modelName]
	return stats, exists
}

// RecordModelUsage records usage statistics for a model
func (mm *ModelManager) RecordModelUsage(modelName string, tokens int64, latency time.Duration, err error) {
	mm.mu.Lock()
	defer mm.mu.Unlock()

	stats, exists := mm.modelStats[modelName]
	if !exists {
		stats = &ModelStats{}
		mm.modelStats[modelName] = stats
	}

	stats.RequestCount++
	stats.TotalTokens += tokens

	if err != nil {
		stats.ErrorCount++
		stats.LastError = err.Error()
		stats.LastErrorAt = time.Now()
	} else {
		// Update average latency
		if stats.AverageLatency == 0 {
			stats.AverageLatency = latency
		} else {
			stats.AverageLatency = time.Duration((int64(stats.AverageLatency) + int64(latency)) / 2)
		}
	}

	// Update model last used time
	if modelInfo, exists := mm.loadedModels[modelName]; exists {
		modelInfo.LastUsed = time.Now()
	}
}

// GetBestModel returns the best model for a given specialization
func (mm *ModelManager) GetBestModel(specialization string) (string, error) {
	mm.mu.RLock()
	defer mm.mu.RUnlock()

	var bestModel string
	var bestPriority int = -1

	for name, info := range mm.loadedModels {
		if info.Status == "loaded" &&
			(info.Specialization == specialization || specialization == "") &&
			info.Priority > bestPriority {
			bestModel = name
			bestPriority = info.Priority
		}
	}

	if bestModel == "" {
		return "", fmt.Errorf("no suitable model found for specialization: %s", specialization)
	}

	return bestModel, nil
}

// GetMemoryStats returns current memory usage
func (mm *ModelManager) GetMemoryStats() *MemoryStats {
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	return &MemoryStats{
		TotalRAM: memStats.Sys,
		UsedRAM:  memStats.Alloc,
		FreeRAM:  memStats.Sys - memStats.Alloc,
		// TODO: Add VRAM monitoring for GPU systems
		TotalVRAM: 0,
		UsedVRAM:  0,
	}
}

// pingOllama checks if Ollama is accessible
func (mm *ModelManager) pingOllama(ctx context.Context) error {
	req, err := http.NewRequestWithContext(ctx, "GET", mm.ollamaBaseURL+"/api/tags", nil)
	if err != nil {
		return err
	}

	resp, err := mm.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("ollama returned status: %d", resp.StatusCode)
	}

	return nil
}

// listAvailableModels gets available models from Ollama
func (mm *ModelManager) listAvailableModels(ctx context.Context) (*OllamaListResponse, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", mm.ollamaBaseURL+"/api/tags", nil)
	if err != nil {
		return nil, err
	}

	resp, err := mm.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to list models, status: %d", resp.StatusCode)
	}

	var listResp OllamaListResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		return nil, err
	}

	return &listResp, nil
}

// processLoadQueue handles model loading requests in background
func (mm *ModelManager) processLoadQueue() {
	for {
		select {
		case req := <-mm.loadQueue:
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
			err := mm.LoadModel(ctx, req.ModelName)
			cancel()

			req.ResponseChan <- err

		case <-mm.shutdown:
			return
		}
	}
}

// monitorModels periodically checks model health and unloads unused models
func (mm *ModelManager) monitorModels() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			mm.cleanupUnusedModels()
		case <-mm.shutdown:
			return
		}
	}
}

// cleanupUnusedModels unloads models that haven't been used recently
func (mm *ModelManager) cleanupUnusedModels() {
	mm.mu.Lock()
	defer mm.mu.Unlock()

	now := time.Now()
	unusedThreshold := 10 * time.Minute

	for name, info := range mm.loadedModels {
		if info.Status == "loaded" && now.Sub(info.LastUsed) > unusedThreshold {
			log.Info().Str("model", name).Msg("Unloading unused model")
			go func(modelName string) {
				ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				defer cancel()
				mm.UnloadModel(ctx, modelName)
			}(name)
		}
	}
}

// Shutdown gracefully shuts down the model manager
func (mm *ModelManager) Shutdown(ctx context.Context) error {
	log.Info().Msg("Shutting down model manager")
	close(mm.shutdown)

	// Unload all models
	for name := range mm.loadedModels {
		if err := mm.UnloadModel(ctx, name); err != nil {
			log.Error().Err(err).Str("model", name).Msg("Failed to unload model during shutdown")
		}
	}

	log.Info().Msg("Model manager shutdown complete")
	return nil
}
