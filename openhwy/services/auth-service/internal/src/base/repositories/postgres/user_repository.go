// internal/repositories/postgres/user.go
package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"auth-service/internal/shared/errors"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// UserRepository implements the UserRepository interface for PostgreSQL
type UserRepository struct {
	db *sqlx.DB
}

// NewUserRepository creates a new PostgreSQL user repository
func NewUserRepository(db *sqlx.DB) *UserRepository {
	return &UserRepository{db: db}
}

// Create creates a new user
func (r *UserRepository) Create(ctx context.Context, user *domain.User) error {
	query := `
		INSERT INTO users (id, email, password_hash, first_name, last_name, role, status, email_verified, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`

	user.ID = uuid.New()
	user.CreatedAt = time.Now().UTC()
	user.UpdatedAt = user.CreatedAt

	_, err := r.db.ExecContext(ctx, query,
		user.ID, user.Email, user.PasswordHash, user.FirstName, user.LastName,
		user.Role, user.Status, user.EmailVerified, user.CreatedAt, user.UpdatedAt)

	if err != nil {
		if isDuplicateKeyError(err) {
			return errors.ErrUserAlreadyExists()
		}
		return errors.ErrDatabaseError(err.Error())
	}

	return nil
}

// GetByID retrieves a user by ID
func (r *UserRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	query := `
		SELECT id, email, password_hash, first_name, last_name, role, status,
			   email_verified, created_at, updated_at, last_login_at
		FROM users WHERE id = $1`

	user := &domain.User{}
	err := r.db.GetContext(ctx, user, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.ErrUserNotFound()
		}
		return nil, errors.ErrDatabaseError(err.Error())
	}

	return user, nil
}

// GetByEmail retrieves a user by email
func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*domain.User, error) {
	query := `
		SELECT id, email, password_hash, first_name, last_name, role, status,
			   email_verified, created_at, updated_at, last_login_at
		FROM users WHERE email = $1`

	user := &domain.User{}
	err := r.db.GetContext(ctx, user, query, email)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.ErrUserNotFound()
		}
		return nil, errors.ErrDatabaseError(err.Error())
	}

	return user, nil
}

// Update updates a user
func (r *UserRepository) Update(ctx context.Context, user *domain.User) error {
	query := `
		UPDATE users
		SET email = $2, password_hash = $3, first_name = $4, last_name = $5,
			role = $6, status = $7, email_verified = $8, updated_at = $9
		WHERE id = $1`

	user.UpdatedAt = time.Now().UTC()

	result, err := r.db.ExecContext(ctx, query,
		user.ID, user.Email, user.PasswordHash, user.FirstName, user.LastName,
		user.Role, user.Status, user.EmailVerified, user.UpdatedAt)

	if err != nil {
		return errors.ErrDatabaseError(err.Error())
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return errors.ErrDatabaseError(err.Error())
	}

	if rowsAffected == 0 {
		return errors.ErrUserNotFound()
	}

	return nil
}

// Delete deletes a user
func (r *UserRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM users WHERE id = $1`

	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return errors.ErrDatabaseError(err.Error())
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return errors.ErrDatabaseError(err.Error())
	}

	if rowsAffected == 0 {
		return errors.ErrUserNotFound()
	}

	return nil
}

// UpdateLastLogin updates the last login time for a user
func (r *UserRepository) UpdateLastLogin(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE users SET last_login_at = $2 WHERE id = $1`

	now := time.Now().UTC()
	result, err := r.db.ExecContext(ctx, query, id, now)
	if err != nil {
		return errors.ErrDatabaseError(err.Error())
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return errors.ErrDatabaseError(err.Error())
	}

	if rowsAffected == 0 {
		return errors.ErrUserNotFound()
	}

	return nil
}

// List retrieves a paginated list of users
func (r *UserRepository) List(ctx context.Context, limit, offset int) ([]*domain.User, error) {
	query := `
		SELECT id, email, password_hash, first_name, last_name, role, status,
			   email_verified, created_at, updated_at, last_login_at
		FROM users
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2`

	var users []*domain.User
	err := r.db.SelectContext(ctx, &users, query, limit, offset)
	if err != nil {
		return nil, errors.ErrDatabaseError(err.Error())
	}

	return users, nil
}

// ExistsByEmail checks if a user exists with the given email
func (r *UserRepository) ExistsByEmail(ctx context.Context, email string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)`

	var exists bool
	err := r.db.GetContext(ctx, &exists, query, email)
	if err != nil {
		return false, errors.ErrDatabaseError(err.Error())
	}

	return exists, nil
}

// isDuplicateKeyError checks if the error is a duplicate key error
func isDuplicateKeyError(err error) bool {
	// PostgreSQL duplicate key error code is 23505
	// This is a simplified check - in production you might want to use pq.Error
	return err != nil && (fmt.Sprintf("%v", err) == "ERROR: duplicate key value violates unique constraint \"users_email_key\" (SQLSTATE 23505)" ||
		fmt.Sprintf("%v", err) == "UNIQUE constraint failed: users.email")
}
