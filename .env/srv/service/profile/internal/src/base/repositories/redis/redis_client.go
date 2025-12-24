// internal/infrastructure/redis/client.go
package redis

import (
	"context"
	"fmt"
	"time"

	"github.com/go-redis/redis/v8"
	"go.uber.org/zap"

	"user_service/internal/config"
	"user_service/internal/shared/logger"
)

type Client struct {
	*redis.Client
	logger logger.Logger
}

func NewClient(cfg config.RedisConfig, logger logger.Logger) (*Client, error) {
	rdb := redis.NewClient(&redis.Options{
		Addr:         fmt.Sprintf("%s:%d", cfg.Host, cfg.Port),
		Password:     cfg.Password,
		DB:           cfg.DB,
		PoolSize:     cfg.PoolSize,
		PoolTimeout:  cfg.PoolTimeout,
		IdleTimeout:  cfg.IdleTimeout,
		ReadTimeout:  cfg.ReadTimeout,
		WriteTimeout: cfg.WriteTimeout,
	})

	// Test the connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := rdb.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to connect to redis: %w", err)
	}

	logger.Info("Redis connection established",
		zap.String("host", cfg.Host),
		zap.Int("port", cfg.Port),
		zap.Int("db", cfg.DB),
	)

	return &Client{
		Client: rdb,
		logger: logger,
	}, nil
}

func (c *Client) Close() error {
	c.logger.Info("Closing Redis connection")
	return c.Client.Close()
}

func (c *Client) HealthCheck() error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return c.Ping(ctx).Err()
}

// Cache interface for user service
type UserCache interface {
	SetUser(ctx context.Context, userID string, user interface{}, ttl time.Duration) error
	GetUser(ctx context.Context, userID string) (string, error)
	DeleteUser(ctx context.Context, userID string) error
}

func (c *Client) SetUser(ctx context.Context, userID string, user interface{}, ttl time.Duration) error {
	key := fmt.Sprintf("user:%s", userID)
	return c.Set(ctx, key, user, ttl).Err()
}

func (c *Client) GetUser(ctx context.Context, userID string) (string, error) {
	key := fmt.Sprintf("user:%s", userID)
	return c.Get(ctx, key).Result()
}

func (c *Client) DeleteUser(ctx context.Context, userID string) error {
	key := fmt.Sprintf("user:%s", userID)
	return c.Del(ctx, key).Err()
}
