// internal/core/ports/cache_service.go
package ports

import (
	"context"
	"time"
)

type CacheService interface {
	Get(ctx context.Context, key string) ([]byte, error)
	Set(ctx context.Context, key string, value []byte, expiration time.Duration) error
	Delete(ctx context.Context, key string) error
	Exists(ctx context.Context, key string) (bool, error)
	Increment(ctx context.Context, key string, delta int64) (int64, error)
	GetMulti(ctx context.Context, keys []string) (map[string][]byte, error)
	SetMulti(ctx context.Context, items map[string][]byte, expiration time.Duration) error
	FlushPattern(ctx context.Context, pattern string) error

	// Rate limiting support
	IsRateLimited(ctx context.Context, key string, limit int64, window time.Duration) (bool, time.Duration, error)

	// Distributed locking
	AcquireLock(ctx context.Context, key string, expiration time.Duration) (bool, error)
	ReleaseLock(ctx context.Context, key string) error
	ExtendLock(ctx context.Context, key string, expiration time.Duration) error
}
