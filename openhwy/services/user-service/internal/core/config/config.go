// internal/config/config.go
package config

import (
	"fmt"
	"time"

	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	Server   ServerConfig   `envconfig:"SERVER"`
	Database DatabaseConfig `envconfig:"DATABASE"`
	Auth     AuthConfig     `envconfig:"AUTH"`
	Redis    RedisConfig    `envconfig:"REDIS"`
	Logging  LoggingConfig  `envconfig:"LOGGING"`
	Metrics  MetricsConfig  `envconfig:"METRICS"`
}

type ServerConfig struct {
	Port            int           `envconfig:"PORT" default:"8080"`
	Host            string        `envconfig:"HOST" default:"0.0.0.0"`
	Environment     string        `envconfig:"ENVIRONMENT" default:"development"`
	ReadTimeout     time.Duration `envconfig:"READ_TIMEOUT" default:"30s"`
	WriteTimeout    time.Duration `envconfig:"WRITE_TIMEOUT" default:"30s"`
	IdleTimeout     time.Duration `envconfig:"IDLE_TIMEOUT" default:"120s"`
	ShutdownTimeout time.Duration `envconfig:"SHUTDOWN_TIMEOUT" default:"30s"`
	GRPCPort        int           `envconfig:"GRPC_PORT" default:"9090"`
}

type DatabaseConfig struct {
	Host            string        `envconfig:"HOST" required:"true"`
	Port            int           `envconfig:"PORT" default:"5432"`
	Name            string        `envconfig:"NAME" required:"true"`
	Username        string        `envconfig:"USERNAME" required:"true"`
	Password        string        `envconfig:"PASSWORD" required:"true"`
	SSLMode         string        `envconfig:"SSL_MODE" default:"disable"`
	MaxOpenConns    int           `envconfig:"MAX_OPEN_CONNS" default:"25"`
	MaxIdleConns    int           `envconfig:"MAX_IDLE_CONNS" default:"5"`
	ConnMaxLifetime time.Duration `envconfig:"CONN_MAX_LIFETIME" default:"5m"`
	ConnMaxIdleTime time.Duration `envconfig:"CONN_MAX_IDLE_TIME" default:"1m"`
	MigrationsPath  string        `envconfig:"MIGRATIONS_PATH" default:"./internal/infrastructure/database/migrations"`
}

type AuthConfig struct {
	JWTSecret            string        `envconfig:"JWT_SECRET" required:"true"`
	JWTExpiration        time.Duration `envconfig:"JWT_EXPIRATION" default:"24h"`
	RefreshExpiration    time.Duration `envconfig:"REFRESH_EXPIRATION" default:"168h"` // 7 days
	PasswordMinLength    int           `envconfig:"PASSWORD_MIN_LENGTH" default:"8"`
	MaxLoginAttempts     int           `envconfig:"MAX_LOGIN_ATTEMPTS" default:"5"`
	LoginLockoutDuration time.Duration `envconfig:"LOGIN_LOCKOUT_DURATION" default:"15m"`
}

type RedisConfig struct {
	Host         string        `envconfig:"HOST" default:"localhost"`
	Port         int           `envconfig:"PORT" default:"6379"`
	Password     string        `envconfig:"PASSWORD" default:""`
	DB           int           `envconfig:"DB" default:"0"`
	PoolSize     int           `envconfig:"POOL_SIZE" default:"10"`
	PoolTimeout  time.Duration `envconfig:"POOL_TIMEOUT" default:"30s"`
	IdleTimeout  time.Duration `envconfig:"IDLE_TIMEOUT" default:"5m"`
	ReadTimeout  time.Duration `envconfig:"READ_TIMEOUT" default:"3s"`
	WriteTimeout time.Duration `envconfig:"WRITE_TIMEOUT" default:"3s"`
}

type LoggingConfig struct {
	Level       string   `envconfig:"LEVEL" default:"info"`
	Format      string   `envconfig:"FORMAT" default:"json"` // json or console
	OutputPaths []string `envconfig:"OUTPUT_PATHS" default:"stdout"`
}

type MetricsConfig struct {
	Enabled bool   `envconfig:"ENABLED" default:"true"`
	Path    string `envconfig:"PATH" default:"/metrics"`
	Port    int    `envconfig:"PORT" default:"9091"`
}

func Load() (*Config, error) {
	var cfg Config

	if err := envconfig.Process("", &cfg); err != nil {
		return nil, fmt.Errorf("failed to load configuration: %w", err)
	}

	if err := cfg.Validate(); err != nil {
		return nil, fmt.Errorf("configuration validation failed: %w", err)
	}

	return &cfg, nil
}

func (c *Config) Validate() error {
	if c.Server.Port <= 0 || c.Server.Port > 65535 {
		return fmt.Errorf("invalid server port: %d", c.Server.Port)
	}

	if c.Server.GRPCPort <= 0 || c.Server.GRPCPort > 65535 {
		return fmt.Errorf("invalid gRPC port: %d", c.Server.GRPCPort)
	}

	if c.Database.MaxOpenConns <= 0 {
		return fmt.Errorf("database max open connections must be positive")
	}

	if c.Database.MaxIdleConns < 0 {
		return fmt.Errorf("database max idle connections must be non-negative")
	}

	if c.Auth.PasswordMinLength < 6 {
		return fmt.Errorf("password minimum length must be at least 6")
	}

	if c.Auth.MaxLoginAttempts <= 0 {
		return fmt.Errorf("max login attempts must be positive")
	}

	validLogLevels := map[string]bool{
		"debug": true, "info": true, "warn": true, "error": true, "fatal": true,
	}
	if !validLogLevels[c.Logging.Level] {
		return fmt.Errorf("invalid log level: %s", c.Logging.Level)
	}

	validLogFormats := map[string]bool{"json": true, "console": true}
	if !validLogFormats[c.Logging.Format] {
		return fmt.Errorf("invalid log format: %s", c.Logging.Format)
	}

	return nil
}

func (c *Config) IsDevelopment() bool {
	return c.Server.Environment == "development"
}

func (c *Config) IsProduction() bool {
	return c.Server.Environment == "production"
}

func (c *Config) DatabaseDSN() string {
	return fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		c.Database.Host,
		c.Database.Port,
		c.Database.Username,
		c.Database.Password,
		c.Database.Name,
		c.Database.SSLMode,
	)
}

func (c *Config) RedisAddr() string {
	return fmt.Sprintf("%s:%d", c.Redis.Host, c.Redis.Port)
}
