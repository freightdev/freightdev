// internal/repositories/interfaces.go
package repositories

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// UserRepository defines the interface for user data operations
type UserRepository interface {
	Create(ctx context.Context, user *domain.User) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error)
	GetByEmail(ctx context.Context, email string) (*domain.User, error)
	Update(ctx context.Context, user *domain.User) error
	Delete(ctx context.Context, id uuid.UUID) error
	UpdateLastLogin(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, limit, offset int) ([]*domain.User, error)
	ExistsByEmail(ctx context.Context, email string) (bool, error)
}

// SessionRepository defines the interface for session data operations
type SessionRepository interface {
	Create(ctx context.Context, session *domain.Session) error
	GetByToken(ctx context.Context, token string) (*domain.Session, error)
	GetByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.Session, error)
	Update(ctx context.Context, session *domain.Session) error
	Delete(ctx context.Context, id uuid.UUID) error
	DeleteByUserID(ctx context.Context, userID uuid.UUID) error
	DeleteExpired(ctx context.Context) error
	RevokeAllByUserID(ctx context.Context, userID uuid.UUID) error
}

// TokenBlacklistRepository defines the interface for token blacklist operations
type TokenBlacklistRepository interface {
	Add(ctx context.Context, tokenID string, expiresAt time.Time) error
	IsBlacklisted(ctx context.Context, tokenID string) (bool, error)
	CleanExpired(ctx context.Context) error
}

// LoginAttemptRepository defines the interface for login attempt tracking
type LoginAttemptRepository interface {
	RecordAttempt(ctx context.Context, email, ipAddress string, success bool) error
	GetFailedAttempts(ctx context.Context, email string, since time.Time) (int, error)
	ClearAttempts(ctx context.Context, email string) error
	IsLocked(ctx context.Context, email string) (bool, time.Time, error)
}
