// internal/domain/entities/enums.go
package entities

// UserStatus represents the status of a user account
type UserStatus string

const (
	UserStatusActive    UserStatus = "active"
	UserStatusInactive  UserStatus = "inactive"
	UserStatusSuspended UserStatus = "suspended"
	UserStatusPending   UserStatus = "pending"
)

// TokenType represents different types of tokens
type TokenType string

const (
	TokenTypeAccess            TokenType = "access"
	TokenTypeRefresh           TokenType = "refresh"
	TokenTypeResetPassword     TokenType = "reset_password"
	TokenTypeEmailVerification TokenType = "email_verification"
)
