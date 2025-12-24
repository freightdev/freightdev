// internal/domain/repositories/user_repository.go
package repositories

import (
	"context"
	"time"
	"user_service/internal/domain/entities"

	"github.com/google/uuid"
)

type UserRepository interface {
	// User CRUD operations
	Create(ctx context.Context, user *entities.User) error
	GetByID(ctx context.Context, id uuid.UUID) (*entities.User, error)
	GetByEmail(ctx context.Context, email string) (*entities.User, error)
	GetByUsername(ctx context.Context, username string) (*entities.User, error)
	Update(ctx context.Context, user *entities.User) error
	Delete(ctx context.Context, id uuid.UUID) error

	// User queries
	List(ctx context.Context, filter UserFilter) ([]*entities.User, error)
	Count(ctx context.Context, filter UserFilter) (int64, error)
	ExistsByEmail(ctx context.Context, email string) (bool, error)
	ExistsByUsername(ctx context.Context, username string) (bool, error)

	// Bulk operations
	UpdateStatus(ctx context.Context, ids []uuid.UUID, status entities.UserStatus) error
	GetActiveUsers(ctx context.Context, limit int) ([]*entities.User, error)
	GetUsersCreatedAfter(ctx context.Context, after time.Time) ([]*entities.User, error)
}

type ProfileRepository interface {
	// Profile CRUD operations
	Create(ctx context.Context, profile *entities.Profile) error
	GetByID(ctx context.Context, id uuid.UUID) (*entities.Profile, error)
	GetByUserID(ctx context.Context, userID uuid.UUID) (*entities.Profile, error)
	Update(ctx context.Context, profile *entities.Profile) error
	Delete(ctx context.Context, id uuid.UUID) error
	DeleteByUserID(ctx context.Context, userID uuid.UUID) error
}

// Filter structs for queries
type UserFilter struct {
	Status         *entities.UserStatus
	Email          *string
	Username       *string
	CreatedAfter   *time.Time
	CreatedBefore  *time.Time
	LastLoginAfter *time.Time
	SearchTerm     *string // for searching across multiple fields
	Limit          int
	Offset         int
	SortBy         string // "created_at", "updated_at", "last_login_at", "email", "username"
	SortOrder      string // "asc", "desc"
}
