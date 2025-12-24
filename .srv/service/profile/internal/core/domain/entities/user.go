// internal/domain/entities/user.go
package entities

import (
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type UserStatus string

const (
	UserStatusActive    UserStatus = "active"
	UserStatusInactive  UserStatus = "inactive"
	UserStatusSuspended UserStatus = "suspended"
	UserStatusPending   UserStatus = "pending"
)

type User struct {
	ID           uuid.UUID  `json:"id" db:"id"`
	Email        string     `json:"email" db:"email"`
	Username     string     `json:"username" db:"username"`
	PasswordHash string     `json:"-" db:"password_hash"`
	Status       UserStatus `json:"status" db:"status"`
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at" db:"updated_at"`
	LastLoginAt  *time.Time `json:"last_login_at,omitempty" db:"last_login_at"`
	Profile      *Profile   `json:"profile,omitempty"`
}

// Business logic methods
func NewUser(email, username, password string) (*User, error) {
	if email == "" || username == "" || password == "" {
		return nil, ErrInvalidUserData
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	return &User{
		ID:           uuid.New(),
		Email:        email,
		Username:     username,
		PasswordHash: string(hashedPassword),
		Status:       UserStatusPending,
		CreatedAt:    time.Now().UTC(),
		UpdatedAt:    time.Now().UTC(),
	}, nil
}

func (u *User) ValidatePassword(password string) error {
	return bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password))
}

func (u *User) Activate() error {
	if u.Status == UserStatusActive {
		return ErrUserAlreadyActive
	}
	u.Status = UserStatusActive
	u.UpdatedAt = time.Now().UTC()
	return nil
}

func (u *User) Suspend() error {
	if u.Status == UserStatusSuspended {
		return ErrUserAlreadySuspended
	}
	u.Status = UserStatusSuspended
	u.UpdatedAt = time.Now().UTC()
	return nil
}

func (u *User) UpdateLastLogin() {
	now := time.Now().UTC()
	u.LastLoginAt = &now
	u.UpdatedAt = now
}

func (u *User) CanLogin() bool {
	return u.Status == UserStatusActive
}
