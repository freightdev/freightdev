// internal/domain/entities/user.go
package entities

import (
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// User represents the user entity in our domain
type User struct {
	ID            uuid.UUID  `json:"id" db:"id"`
	Email         string     `json:"email" db:"email"`
	PasswordHash  string     `json:"-" db:"password_hash"`
	FirstName     string     `json:"first_name" db:"first_name"`
	LastName      string     `json:"last_name" db:"last_name"`
	Role          Role       `json:"role" db:"role"`
	Status        UserStatus `json:"status" db:"status"`
	EmailVerified bool       `json:"email_verified" db:"email_verified"`
	CreatedAt     time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at" db:"updated_at"`
	LastLoginAt   *time.Time `json:"last_login_at,omitempty" db:"last_login_at"`
}

// SetPassword hashes and sets the user password
func (u *User) SetPassword(password string) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	u.PasswordHash = string(hash)
	return nil
}

// CheckPassword verifies the password against the stored hash
func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password))
	return err == nil
}

// IsActive returns true if the user account is active
func (u *User) IsActive() bool {
	return u.Status == UserStatusActive
}

// CanAccess checks if user has required permission
func (u *User) CanAccess(permission Permission) bool {
	return u.Role.HasPermission(permission)
}
