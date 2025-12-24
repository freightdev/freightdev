// internal/domain/entities/errors.go (same file for brevity)

import "errors"

var (
	ErrUserNotFound         = errors.New("user not found")
	ErrUserAlreadyExists    = errors.New("user already exists")
	ErrUserAlreadyActive    = errors.New("user already active")
	ErrUserAlreadySuspended = errors.New("user already suspended")
	ErrInvalidUserData      = errors.New("invalid user data")
	ErrInvalidCredentials   = errors.New("invalid credentials")
	ErrProfileNotFound      = errors.New("profile not found")
	ErrUnauthorized         = errors.New("unauthorized")
)
