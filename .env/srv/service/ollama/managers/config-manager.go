// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = managers/config-manager.go

package managers

import (
	// stdlib
	"fmt"
	"os"
	"sync"

	// third-party
	"gopkg.in/yaml.v3"
)

// ConfigManager handles all configuration loading and management
type ConfigManager struct {
	mu       sync.RWMutex
	configs  map[string]interface{}
	watchers map[string][]func(interface{})
}

// ServerConfig represents server configuration
type ServerConfig struct {
	Host         string `yaml:"host"`
	Port         int    `yaml:"port"`
	ReadTimeout  int    `yaml:"read_timeout"`
	WriteTimeout int    `yaml:"write_timeout"`
	IdleTimeout  int    `yaml:"idle_timeout"`
	Environment  string `yaml:"environment"`
}

// ModelConfig represents model configuration
type ModelConfig struct {
	Name           string            `yaml:"name"`
	MaxTokens      int               `yaml:"max_tokens"`
	Temperature    float64           `yaml:"temperature"`
	SystemPrompt   string            `yaml:"system_prompt"`
	Specialization string            `yaml:"specialization"`
	ContextWindow  int               `yaml:"context_window"`
	Parameters     map[string]string `yaml:"parameters"`
	LoadOnStartup  bool              `yaml:"load_on_startup"`
	Priority       int               `yaml:"priority"`
}

// LimitsConfig represents rate limiting and quotas
type LimitsConfig struct {
	MaxRequestsPerMinute int   `yaml:"max_requests_per_minute"`
	MaxTokensPerRequest  int   `yaml:"max_tokens_per_request"`
	MaxContextLength     int   `yaml:"max_context_length"`
	MaxConcurrentChats   int   `yaml:"max_concurrent_chats"`
	TokenBudgetPerUser   int64 `yaml:"token_budget_per_user"`
	ResetIntervalHours   int   `yaml:"reset_interval_hours"`
}

// FeatureConfig represents feature flags
type FeatureConfig struct {
	EnableCodeTools      bool `yaml:"enable_code_tools"`
	EnableFileTools      bool `yaml:"enable_file_tools"`
	EnableWebSearch      bool `yaml:"enable_web_search"`
	EnableMemoryPersist  bool `yaml:"enable_memory_persist"`
	EnableModelRouting   bool `yaml:"enable_model_routing"`
	EnableTokenOptimizer bool `yaml:"enable_token_optimizer"`
	EnableAutoBackup     bool `yaml:"enable_auto_backup"`
}

// PersonaConfig represents AI personality configurations
type PersonaConfig struct {
	Name        string            `yaml:"name"`
	Description string            `yaml:"description"`
	Traits      []string          `yaml:"traits"`
	Prompts     map[string]string `yaml:"prompts"`
	Temperature float64           `yaml:"temperature"`
	MaxTokens   int               `yaml:"max_tokens"`
}

// PromptTemplate represents reusable prompt templates
type PromptTemplate struct {
	Name        string            `yaml:"name"`
	Template    string            `yaml:"template"`
	Variables   []string          `yaml:"variables"`
	Category    string            `yaml:"category"`
	Description string            `yaml:"description"`
	Examples    map[string]string `yaml:"examples"`
}

var (
	configManager *ConfigManager
	once          sync.Once
)

// GetConfigManager returns singleton config manager instance
func GetConfigManager() *ConfigManager {
	once.Do(func() {
		configManager = &ConfigManager{
			configs:  make(map[string]interface{}),
			watchers: make(map[string][]func(interface{})),
		}
	})
	return configManager
}

// LoadConfig loads configuration from YAML file
func (cm *ConfigManager) LoadConfig(configPath string, target interface{}) error {
	cm.mu.Lock()
	defer cm.mu.Unlock()

	data, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read config file %s: %w", configPath, err)
	}

	if err := yaml.Unmarshal(data, target); err != nil {
		return fmt.Errorf("failed to unmarshal config from %s: %w", configPath, err)
	}

	// Store config in memory for quick access
	cm.configs[configPath] = target

	// Notify watchers
	if watchers, exists := cm.watchers[configPath]; exists {
		for _, watcher := range watchers {
			go watcher(target)
		}
	}

	return nil
}

// LoadAllConfigs loads all configuration files
func (cm *ConfigManager) LoadAllConfigs() error {
	configs := map[string]interface{}{
		"configs/server.yaml":                 &ServerConfig{},
		"configs/models.yaml":                 &[]ModelConfig{},
		"configs/limits.yaml":                 &LimitsConfig{},
		"configs/features.yaml":               &FeatureConfig{},
		"configs/model/personas.yaml":         &[]PersonaConfig{},
		"configs/model/prompt-templates.yaml": &[]PromptTemplate{},
	}

	for path, target := range configs {
		if err := cm.LoadConfig(path, target); err != nil {
			return fmt.Errorf("failed to load %s: %w", path, err)
		}
	}

	return nil
}

// GetConfig retrieves configuration by path
func (cm *ConfigManager) GetConfig(configPath string) (interface{}, bool) {
	cm.mu.RLock()
	defer cm.mu.RUnlock()

	config, exists := cm.configs[configPath]
	return config, exists
}

// GetServerConfig returns server configuration
func (cm *ConfigManager) GetServerConfig() (*ServerConfig, error) {
	config, exists := cm.GetConfig("configs/server.yaml")
	if !exists {
		return nil, fmt.Errorf("server config not loaded")
	}

	serverConfig, ok := config.(*ServerConfig)
	if !ok {
		return nil, fmt.Errorf("invalid server config type")
	}

	return serverConfig, nil
}

// GetModelConfigs returns all model configurations
func (cm *ConfigManager) GetModelConfigs() ([]ModelConfig, error) {
	config, exists := cm.GetConfig("configs/models.yaml")
	if !exists {
		return nil, fmt.Errorf("model configs not loaded")
	}

	modelConfigs, ok := config.(*[]ModelConfig)
	if !ok {
		return nil, fmt.Errorf("invalid model configs type")
	}

	return *modelConfigs, nil
}

// GetModelConfig returns specific model configuration
func (cm *ConfigManager) GetModelConfig(modelName string) (*ModelConfig, error) {
	configs, err := cm.GetModelConfigs()
	if err != nil {
		return nil, err
	}

	for _, config := range configs {
		if config.Name == modelName {
			return &config, nil
		}
	}

	return nil, fmt.Errorf("model config not found: %s", modelName)
}

// GetLimitsConfig returns rate limiting configuration
func (cm *ConfigManager) GetLimitsConfig() (*LimitsConfig, error) {
	config, exists := cm.GetConfig("configs/limits.yaml")
	if !exists {
		return nil, fmt.Errorf("limits config not loaded")
	}

	limitsConfig, ok := config.(*LimitsConfig)
	if !ok {
		return nil, fmt.Errorf("invalid limits config type")
	}

	return limitsConfig, nil
}

// GetFeatureConfig returns feature flags configuration
func (cm *ConfigManager) GetFeatureConfig() (*FeatureConfig, error) {
	config, exists := cm.GetConfig("configs/features.yaml")
	if !exists {
		return nil, fmt.Errorf("feature config not loaded")
	}

	featureConfig, ok := config.(*FeatureConfig)
	if !ok {
		return nil, fmt.Errorf("invalid feature config type")
	}

	return featureConfig, nil
}

// GetPersonaConfigs returns all persona configurations
func (cm *ConfigManager) GetPersonaConfigs() ([]PersonaConfig, error) {
	config, exists := cm.GetConfig("configs/model/personas.yaml")
	if !exists {
		return nil, fmt.Errorf("persona configs not loaded")
	}

	personaConfigs, ok := config.(*[]PersonaConfig)
	if !ok {
		return nil, fmt.Errorf("invalid persona configs type")
	}

	return *personaConfigs, nil
}

// GetPersonaConfig returns specific persona configuration
func (cm *ConfigManager) GetPersonaConfig(personaName string) (*PersonaConfig, error) {
	configs, err := cm.GetPersonaConfigs()
	if err != nil {
		return nil, err
	}

	for _, config := range configs {
		if config.Name == personaName {
			return &config, nil
		}
	}

	return nil, fmt.Errorf("persona config not found: %s", personaName)
}

// GetPromptTemplates returns all prompt templates
func (cm *ConfigManager) GetPromptTemplates() ([]PromptTemplate, error) {
	config, exists := cm.GetConfig("configs/model/prompt-templates.yaml")
	if !exists {
		return nil, fmt.Errorf("prompt templates not loaded")
	}

	templates, ok := config.(*[]PromptTemplate)
	if !ok {
		return nil, fmt.Errorf("invalid prompt templates type")
	}

	return *templates, nil
}

// GetPromptTemplate returns specific prompt template
func (cm *ConfigManager) GetPromptTemplate(templateName string) (*PromptTemplate, error) {
	templates, err := cm.GetPromptTemplates()
	if err != nil {
		return nil, err
	}

	for _, template := range templates {
		if template.Name == templateName {
			return &template, nil
		}
	}

	return nil, fmt.Errorf("prompt template not found: %s", templateName)
}

// WatchConfig adds a watcher for configuration changes
func (cm *ConfigManager) WatchConfig(configPath string, callback func(interface{})) {
	cm.mu.Lock()
	defer cm.mu.Unlock()

	cm.watchers[configPath] = append(cm.watchers[configPath], callback)
}

// ReloadConfig reloads a specific configuration file
func (cm *ConfigManager) ReloadConfig(configPath string, target interface{}) error {
	return cm.LoadConfig(configPath, target)
}

// IsFeatureEnabled checks if a feature is enabled
func (cm *ConfigManager) IsFeatureEnabled(featureName string) bool {
	featureConfig, err := cm.GetFeatureConfig()
	if err != nil {
		return false
	}

	switch featureName {
	case "code_tools":
		return featureConfig.EnableCodeTools
	case "file_tools":
		return featureConfig.EnableFileTools
	case "web_search":
		return featureConfig.EnableWebSearch
	case "memory_persist":
		return featureConfig.EnableMemoryPersist
	case "model_routing":
		return featureConfig.EnableModelRouting
	case "token_optimizer":
		return featureConfig.EnableTokenOptimizer
	case "auto_backup":
		return featureConfig.EnableAutoBackup
	default:
		return false
	}
}

// ValidateConfigs validates all loaded configurations
func (cm *ConfigManager) ValidateConfigs() error {
	// Validate server config
	serverConfig, err := cm.GetServerConfig()
	if err != nil {
		return err
	}
	if serverConfig.Port <= 0 || serverConfig.Port > 65535 {
		return fmt.Errorf("invalid server port: %d", serverConfig.Port)
	}

	// Validate model configs
	modelConfigs, err := cm.GetModelConfigs()
	if err != nil {
		return err
	}
	if len(modelConfigs) == 0 {
		return fmt.Errorf("no model configurations found")
	}

	for _, config := range modelConfigs {
		if config.Name == "" {
			return fmt.Errorf("model config missing name")
		}
		if config.MaxTokens <= 0 {
			return fmt.Errorf("invalid max_tokens for model %s: %d", config.Name, config.MaxTokens)
		}
		if config.Temperature < 0 || config.Temperature > 2 {
			return fmt.Errorf("invalid temperature for model %s: %f", config.Name, config.Temperature)
		}
	}

	// Validate limits config
	limitsConfig, err := cm.GetLimitsConfig()
	if err != nil {
		return err
	}
	if limitsConfig.MaxRequestsPerMinute <= 0 {
		return fmt.Errorf("invalid max_requests_per_minute: %d", limitsConfig.MaxRequestsPerMinute)
	}

	return nil
}
