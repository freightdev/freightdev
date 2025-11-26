// internal/adapters/repository/redis/cache_service.go
package redis

import (
	"context"
	"fmt"
	"time"

	"payment-service/internal/core/ports"
	"payment-service/pkg/logger"

	"github.com/go-redis/redis/v8"
)

type CacheService struct {
	client *redis.Client
	logger logger.Logger
}

func NewCacheService(client *redis.Client, logger logger.Logger) ports.CacheService {
	return &CacheService{
		client: client,
		logger: logger,
	}
}

func (c *CacheService) Get(ctx context.Context, key string) ([]byte, error) {
	result, err := c.client.Get(ctx, key).Result()
	if err != nil {
		if err == redis.Nil {
			return nil, fmt.Errorf("key not found: %s", key)
		}
		return nil, fmt.Errorf("failed to get key %s: %w", key, err)
	}

	return []byte(result), nil
}

func (c *CacheService) Set(ctx context.Context, key string, value []byte, expiration time.Duration) error {
	err := c.client.Set(ctx, key, value, expiration).Err()
	if err != nil {
		return fmt.Errorf("failed to set key %s: %w", key, err)
	}

	return nil
}

func (c *CacheService) Delete(ctx context.Context, key string) error {
	err := c.client.Del(ctx, key).Err()
	if err != nil {
		return fmt.Errorf("failed to delete key %s: %w", key, err)
	}

	return nil
}

func (c *CacheService) Exists(ctx context.Context, key string) (bool, error) {
	result, err := c.client.Exists(ctx, key).Result()
	if err != nil {
		return false, fmt.Errorf("failed to check key existence %s: %w", key, err)
	}

	return result > 0, nil
}

func (c *CacheService) Increment(ctx context.Context, key string, delta int64) (int64, error) {
	result, err := c.client.IncrBy(ctx, key, delta).Result()
	if err != nil {
		return 0, fmt.Errorf("failed to increment key %s: %w", key, err)
	}

	return result, nil
}

func (c *CacheService) GetMulti(ctx context.Context, keys []string) (map[string][]byte, error) {
	if len(keys) == 0 {
		return make(map[string][]byte), nil
	}

	results, err := c.client.MGet(ctx, keys...).Result()
	if err != nil {
		return nil, fmt.Errorf("failed to get multiple keys: %w", err)
	}

	items := make(map[string][]byte)
	for i, result := range results {
		if result != nil {
			if str, ok := result.(string); ok {
				items[keys[i]] = []byte(str)
			}
		}
	}

	return items, nil
}

func (c *CacheService) SetMulti(ctx context.Context, items map[string][]byte, expiration time.Duration) error {
	pipe := c.client.Pipeline()

	for key, value := range items {
		pipe.Set(ctx, key, value, expiration)
	}

	_, err := pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to set multiple keys: %w", err)
	}

	return nil
}

func (c *CacheService) FlushPattern(ctx context.Context, pattern string) error {
	keys, err := c.client.Keys(ctx, pattern).Result()
	if err != nil {
		return fmt.Errorf("failed to get keys by pattern %s: %w", pattern, err)
	}

	if len(keys) > 0 {
		err = c.client.Del(ctx, keys...).Err()
		if err != nil {
			return fmt.Errorf("failed to delete keys: %w", err)
		}
	}

	return nil
}

func (c *CacheService) IsRateLimited(ctx context.Context, key string, limit int64, window time.Duration) (bool, time.Duration, error) {
	windowKey := fmt.Sprintf("rate_limit:%s:%d", key, time.Now().Unix()/int64(window.Seconds()))

	current, err := c.client.Incr(ctx, windowKey).Result()
	if err != nil {
		return false, 0, fmt.Errorf("failed to increment rate limit counter: %w", err)
	}

	if current == 1 {
		// First request in this window, set expiration
		c.client.Expire(ctx, windowKey, window)
	}

	if current > limit {
		ttl, _ := c.client.TTL(ctx, windowKey).Result()
		return true, ttl, nil
	}

	return false, 0, nil
}

func (c *CacheService) AcquireLock(ctx context.Context, key string, expiration time.Duration) (bool, error) {
	lockKey := fmt.Sprintf("lock:%s", key)
	result, err := c.client.SetNX(ctx, lockKey, "locked", expiration).Result()
	if err != nil {
		return false, fmt.Errorf("failed to acquire lock %s: %w", key, err)
	}

	return result, nil
}

func (c *CacheService) ReleaseLock(ctx context.Context, key string) error {
	lockKey := fmt.Sprintf("lock:%s", key)
	err := c.client.Del(ctx, lockKey).Err()
	if err != nil {
		return fmt.Errorf("failed to release lock %s: %w", key, err)
	}

	return nil
}

func (c *CacheService) ExtendLock(ctx context.Context, key string, expiration time.Duration) error {
	lockKey := fmt.Sprintf("lock:%s", key)
	err := c.client.Expire(ctx, lockKey, expiration).Err()
	if err != nil {
		return fmt.Errorf("failed to extend lock %s: %w", key, err)
	}

	return nil
}
