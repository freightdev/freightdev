// internal/config/config.go
package config

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

// Config holds all configuration for the service
type Config struct {
	Server   ServerConfig   `json:"server"`
	Database DatabaseConfig `json:"database"`
	JWT      JWTConfig      `json:"jwt"`
	Redis    RedisConfig    `json:"redis"`
	Email    EmailConfig    `json:"email"`
	Security SecurityConfig `json:"security"`
	Logger   LoggerConfig   `json:"logger"`
}

// ServerConfig holds server configuration
type ServerConfig struct {
	Port            string        `json:"port"`
	Host            string        `json:"host"`
	Environment     string        `json:"environment"`
	ReadTimeout     time.Duration `json:"read_timeout"`
	WriteTimeout    time.Duration `json:"write_timeout"`
	ShutdownTimeout time.Duration `json:"shutdown_timeout"`
	CORS            CORSConfig    `json:"cors"`
}

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	Host            string        `json:"host"`
	Port            string        `json:"port"`
	Username        string        `json:"username"`
	Password        string        `json:"-"` // Hide in logs
	Database        string        `json:"database"`
	SSLMode         string        `json:"ssl_mode"`
	MaxOpenConns    int           `json:"max_open_conns"`
	MaxIdleConns    int           `json:"max_idle_conns"`
	ConnMaxLifetime time.Duration `json:"conn_max_lifetime"`
	MigrationPath   string        `json:"migration_path"`
}

// JWTConfig holds JWT configuration
type JWTConfig struct {
	AccessSecret       string        `json:"-"` // Hide in logs
	RefreshSecret      string        `json:"-"` // Hide in logs
	AccessExpiry       time.Duration `json:"access_expiry"`
	RefreshExpiry      time.Duration `json:"refresh_expiry"`
	Issuer             string        `json:"issuer"`
	ResetExpiry        time.Duration `json:"reset_expiry"`
	VerificationExpiry time.Duration `json:"verification_expiry"`
}

// RedisConfig holds Redis configuration
type RedisConfig struct {
	Host        string        `json:"host"`
	Port        string        `json:"port"`
	Password    string        `json:"-"` // Hide in logs
	DB          int           `json:"db"`
	PoolSize    int           `json:"pool_size"`
	IdleTimeout time.Duration `json:"idle_timeout"`
}

// EmailConfig holds email configuration
type EmailConfig struct {
	SMTPHost     string `json:"smtp_host"`
	SMTPPort     string `json:"smtp_port"`
	SMTPUsername string `json:"smtp_username"`
	SMTPPassword string `json:"-"` // Hide in logs
	FromEmail    string `json:"from_email"`
	FromName     string `json:"from_name"`
}

// SecurityConfig holds security configuration
type SecurityConfig struct {
	RateLimitRequests int           `json:"rate_limit_requests"`
	RateLimitWindow   time.Duration `json:"rate_limit_window"`
	MaxLoginAttempts  int           `json:"max_login_attempts"`
	LockoutDuration   time.Duration `json:"lockout_duration"`
	PasswordMinLength int           `json:"password_min_length"`
}

// CORSConfig holds CORS configuration
type CORSConfig struct {
	AllowedOrigins []string `json:"allowed_origins"`
	AllowedMethods []string `json:"allowed_methods"`
	AllowedHeaders []string `json:"allowed_headers"`
	MaxAge         int      `json:"max_age"`
}

// LoggerConfig holds logger configuration
type LoggerConfig struct {
	Level  string `json:"level"`
	Format string `json:"format"`
}

// DSN returns the database connection string
func (d *DatabaseConfig) DSN() string {
	return fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		d.Host, d.Port, d.Username, d.Password, d.Database, d.SSLMode)
}

// RedisAddr returns the Redis address
func (r *RedisConfig) Addr() string {
	return fmt.Sprintf("%s:%s", r.Host, r.Port)
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists (for local development)
	_ = godotenv.Load()

	config := &Config{
		Server: ServerConfig{
			Port:            getEnv("SERVER_PORT", "8080"),
			Host:            getEnv("SERVER_HOST", "0.0.0.0"),
			Environment:     getEnv("ENVIRONMENT", "development"),
			ReadTimeout:     getDurationEnv("SERVER_READ_TIMEOUT", "10s"),
			WriteTimeout:    getDurationEnv("SERVER_WRITE_TIMEOUT", "10s"),
			ShutdownTimeout: getDurationEnv("SERVER_SHUTDOWN_TIMEOUT", "5s"),
			CORS: CORSConfig{
				AllowedOrigins: getSliceEnv("CORS_ALLOWED_ORIGINS", []string{"*"}),
				AllowedMethods: getSliceEnv("CORS_ALLOWED_METHODS", []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}),
				AllowedHeaders: getSliceEnv("CORS_ALLOWED_HEADERS", []string{"*"}),
				MaxAge:         getIntEnv("CORS_MAX_AGE", 86400),
			},
		},
		Database: DatabaseConfig{
			Host:            getEnv("DB_HOST", "localhost"),
			Port:            getEnv("DB_PORT", "5432"),
			Username:        getEnv("DB_USERNAME", "postgres"),
			Password:        getEnv("DB_PASSWORD", ""),
			Database:        getEnv("DB_NAME", "auth_service"),
			SSLMode:         getEnv("DB_SSL_MODE", "disable"),
			MaxOpenConns:    getIntEnv("DB_MAX_OPEN_CONNS", 25),
			MaxIdleConns:    getIntEnv("DB_MAX_IDLE_CONNS", 10),
			ConnMaxLifetime: getDurationEnv("DB_CONN_MAX_LIFETIME", "5m"),
			MigrationPath:   getEnv("DB_MIGRATION_PATH", "file://migrations"),
		},
		JWT: JWTConfig{
			AccessSecret:       getEnv("JWT_ACCESS_SECRET", ""),
			RefreshSecret:      getEnv("JWT_REFRESH_SECRET", ""),
			AccessExpiry:       getDurationEnv("JWT_ACCESS_EXPIRY", "15m"),
			RefreshExpiry:      getDurationEnv("JWT_REFRESH_EXPIRY", "7d"),
			Issuer:             getEnv("JWT_ISSUER", "auth-service"),
			ResetExpiry:        getDurationEnv("JWT_RESET_EXPIRY", "1h"),
			VerificationExpiry: getDurationEnv("JWT_VERIFICATION_EXPIRY", "24h"),
		},
		Redis: RedisConfig{
			Host:        getEnv("REDIS_HOST", "localhost"),
			Port:        getEnv("REDIS_PORT", "6379"),
			Password:    getEnv("REDIS_PASSWORD", ""),
			DB:          getIntEnv("REDIS_DB", 0),
			PoolSize:    getIntEnv("REDIS_POOL_SIZE", 10),
			IdleTimeout: getDurationEnv("REDIS_IDLE_TIMEOUT", "5m"),
		},
		Email: EmailConfig{
			SMTPHost:     getEnv("SMTP_HOST", ""),
			SMTPPort:     getEnv("SMTP_PORT", "587"),
			SMTPUsername: getEnv("SMTP_USERNAME", ""),
			SMTPPassword: getEnv("SMTP_PASSWORD", ""),
			FromEmail:    getEnv("FROM_EMAIL", ""),
			FromName:     getEnv("FROM_NAME", "Auth Service"),
		},
		Security: SecurityConfig{
			RateLimitRequests: getIntEnv("RATE_LIMIT_REQUESTS", 100),
			RateLimitWindow:   getDurationEnv("RATE_LIMIT_WINDOW", "1h"),
			MaxLoginAttempts:  getIntEnv("MAX_LOGIN_ATTEMPTS", 5),
			LockoutDuration:   getDurationEnv("LOCKOUT_DURATION", "15m"),
			PasswordMinLength: getIntEnv("PASSWORD_MIN_LENGTH", 8),
		},
		Logger: LoggerConfig{
			Level:  getEnv("LOG_LEVEL", "info"),
			Format: getEnv("LOG_FORMAT", "json"),
		},
	}

	if err := config.validate(); err != nil {
		return nil, fmt.Errorf("config validation failed: %w", err)
	}

	return config, nil
}

// validate validates the configuration
func (c *Config) validate() error {
	if c.JWT.AccessSecret == "" {
		return fmt.Errorf("JWT_ACCESS_SECRET is required")
	}
	if c.JWT.RefreshSecret == "" {
		return fmt.Errorf("JWT_REFRESH_SECRET is required")
	}
	if c.Database.Password == "" {
		return fmt.Errorf("DB_PASSWORD is required")
	}
	return nil
}

// Helper functions for environment variables
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getIntEnv(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intVal, err := strconv.Atoi(value); err == nil {
			return intVal
		}
	}
	return defaultValue
}

func getDurationEnv(key string, defaultValue string) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	duration, _ := time.ParseDuration(defaultValue)
	return duration
}

func getSliceEnv(key string, defaultValue []string) []string {
	if value := os.Getenv(key); value != "" {
		// Simple comma-separated parsing
		// In production, you might want more sophisticated parsing
		return []string{value}
	}
	return defaultValue
}
