// internal/core/config/config.go
package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	Server   ServerConfig   `json:"server"`
	Database DatabaseConfig `json:"database"`
	Redis    RedisConfig    `json:"redis"`
	Payment  PaymentConfig  `json:"payment"`
	Security SecurityConfig `json:"security"`
	Logging  LoggingConfig  `json:"logging"`
}

type ServerConfig struct {
	Host            string        `json:"host"`
	Port            int           `json:"port"`
	ReadTimeout     time.Duration `json:"read_timeout"`
	WriteTimeout    time.Duration `json:"write_timeout"`
	IdleTimeout     time.Duration `json:"idle_timeout"`
	ShutdownTimeout time.Duration `json:"shutdown_timeout"`
}

type DatabaseConfig struct {
	Host            string        `json:"host"`
	Port            int           `json:"port"`
	User            string        `json:"user"`
	Password        string        `json:"password"`
	Name            string        `json:"name"`
	SSLMode         string        `json:"ssl_mode"`
	MaxOpenConns    int           `json:"max_open_conns"`
	MaxIdleConns    int           `json:"max_idle_conns"`
	ConnMaxLifetime time.Duration `json:"conn_max_lifetime"`
	MigrationsPath  string        `json:"migrations_path"`
}

type RedisConfig struct {
	Host     string `json:"host"`
	Port     int    `json:"port"`
	Password string `json:"password"`
	DB       int    `json:"db"`
}

type PaymentConfig struct {
	Processors map[string]ProcessorConfig `json:"processors"`
}

type ProcessorConfig struct {
	Name       string            `json:"name"`
	APIKey     string            `json:"api_key"`
	APISecret  string            `json:"api_secret"`
	BaseURL    string            `json:"base_url"`
	Timeout    time.Duration     `json:"timeout"`
	Retries    int               `json:"retries"`
	Methods    []string          `json:"methods"`
	Currencies []string          `json:"currencies"`
	Metadata   map[string]string `json:"metadata"`
}

type SecurityConfig struct {
	JWTSecret          string        `json:"jwt_secret"`
	JWTExpiration      time.Duration `json:"jwt_expiration"`
	APIKeyRequired     bool          `json:"api_key_required"`
	RateLimitRPS       int           `json:"rate_limit_rps"`
	RateLimitBurst     int           `json:"rate_limit_burst"`
	TLSEnabled         bool          `json:"tls_enabled"`
	TLSCertFile        string        `json:"tls_cert_file"`
	TLSKeyFile         string        `json:"tls_key_file"`
	CORSAllowedOrigins []string      `json:"cors_allowed_origins"`
}

type LoggingConfig struct {
	Level  string `json:"level"`
	Format string `json:"format"`
	Output string `json:"output"`
}

func Load() (*Config, error) {
	// Load .env file if it exists
	if err := godotenv.Load(); err != nil && !os.IsNotExist(err) {
		return nil, fmt.Errorf("error loading .env file: %w", err)
	}

	config := &Config{
		Server: ServerConfig{
			Host:            getEnv("SERVER_HOST", "0.0.0.0"),
			Port:            getEnvAsInt("SERVER_PORT", 8080),
			ReadTimeout:     getEnvAsDuration("SERVER_READ_TIMEOUT", "30s"),
			WriteTimeout:    getEnvAsDuration("SERVER_WRITE_TIMEOUT", "30s"),
			IdleTimeout:     getEnvAsDuration("SERVER_IDLE_TIMEOUT", "120s"),
			ShutdownTimeout: getEnvAsDuration("SERVER_SHUTDOWN_TIMEOUT", "30s"),
		},
		Database: DatabaseConfig{
			Host:            getEnv("DB_HOST", "localhost"),
			Port:            getEnvAsInt("DB_PORT", 5432),
			User:            getEnv("DB_USER", "postgres"),
			Password:        getEnv("DB_PASSWORD", ""),
			Name:            getEnv("DB_NAME", "payment_service"),
			SSLMode:         getEnv("DB_SSL_MODE", "disable"),
			MaxOpenConns:    getEnvAsInt("DB_MAX_OPEN_CONNS", 25),
			MaxIdleConns:    getEnvAsInt("DB_MAX_IDLE_CONNS", 10),
			ConnMaxLifetime: getEnvAsDuration("DB_CONN_MAX_LIFETIME", "1h"),
			MigrationsPath:  getEnv("DB_MIGRATIONS_PATH", "migrations"),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnvAsInt("REDIS_PORT", 6379),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvAsInt("REDIS_DB", 0),
		},
		Payment: PaymentConfig{
			Processors: loadProcessorConfigs(),
		},
		Security: SecurityConfig{
			JWTSecret:          getEnv("JWT_SECRET", "your-secret-key"),
			JWTExpiration:      getEnvAsDuration("JWT_EXPIRATION", "24h"),
			APIKeyRequired:     getEnvAsBool("API_KEY_REQUIRED", true),
			RateLimitRPS:       getEnvAsInt("RATE_LIMIT_RPS", 100),
			RateLimitBurst:     getEnvAsInt("RATE_LIMIT_BURST", 200),
			TLSEnabled:         getEnvAsBool("TLS_ENABLED", false),
			TLSCertFile:        getEnv("TLS_CERT_FILE", ""),
			TLSKeyFile:         getEnv("TLS_KEY_FILE", ""),
			CORSAllowedOrigins: getEnvAsStringSlice("CORS_ALLOWED_ORIGINS", []string{"*"}),
		},
		Logging: LoggingConfig{
			Level:  getEnv("LOG_LEVEL", "info"),
			Format: getEnv("LOG_FORMAT", "json"),
			Output: getEnv("LOG_OUTPUT", "stdout"),
		},
	}

	return config, config.Validate()
}

func (c *Config) Validate() error {
	if c.Server.Port <= 0 || c.Server.Port > 65535 {
		return fmt.Errorf("invalid server port: %d", c.Server.Port)
	}

	if c.Database.Host == "" {
		return fmt.Errorf("database host is required")
	}

	if c.Database.Name == "" {
		return fmt.Errorf("database name is required")
	}

	if c.Security.JWTSecret == "" || c.Security.JWTSecret == "your-secret-key" {
		return fmt.Errorf("JWT secret must be set and not use default value")
	}

	return nil
}

func (c *Config) GetDSN() string {
	return fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		c.Database.Host,
		c.Database.Port,
		c.Database.User,
		c.Database.Password,
		c.Database.Name,
		c.Database.SSLMode,
	)
}

// Helper functions
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return defaultValue
}

func getEnvAsDuration(key string, defaultValue string) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	duration, _ := time.ParseDuration(defaultValue)
	return duration
}

func getEnvAsStringSlice(key string, defaultValue []string) []string {
	if value := os.Getenv(key); value != "" {
		return strings.Split(value, ",")
	}
	return defaultValue
}

func loadProcessorConfigs() map[string]ProcessorConfig {
	processors := make(map[string]ProcessorConfig)

	// Load Stripe configuration
	if apiKey := getEnv("STRIPE_API_KEY", ""); apiKey != "" {
		processors["stripe"] = ProcessorConfig{
			Name:       "stripe",
			APIKey:     apiKey,
			APISecret:  getEnv("STRIPE_API_SECRET", ""),
			BaseURL:    getEnv("STRIPE_BASE_URL", "https://api.stripe.com"),
			Timeout:    getEnvAsDuration("STRIPE_TIMEOUT", "30s"),
			Retries:    getEnvAsInt("STRIPE_RETRIES", 3),
			Methods:    getEnvAsStringSlice("STRIPE_METHODS", []string{"card"}),
			Currencies: getEnvAsStringSlice("STRIPE_CURRENCIES", []string{"USD", "EUR", "GBP"}),
		}
	}

	// Load PayPal configuration
	if apiKey := getEnv("PAYPAL_API_KEY", ""); apiKey != "" {
		processors["paypal"] = ProcessorConfig{
			Name:       "paypal",
			APIKey:     apiKey,
			APISecret:  getEnv("PAYPAL_API_SECRET", ""),
			BaseURL:    getEnv("PAYPAL_BASE_URL", "https://api.paypal.com"),
			Timeout:    getEnvAsDuration("PAYPAL_TIMEOUT", "30s"),
			Retries:    getEnvAsInt("PAYPAL_RETRIES", 3),
			Methods:    getEnvAsStringSlice("PAYPAL_METHODS", []string{"card", "wallet"}),
			Currencies: getEnvAsStringSlice("PAYPAL_CURRENCIES", []string{"USD", "EUR", "GBP"}),
		}
	}

	return processors
}
