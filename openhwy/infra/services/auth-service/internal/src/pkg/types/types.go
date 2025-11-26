// pkg/types/auth.go
package types

import (
	"time"

	"github.com/google/uuid"
)

// LoginRequest represents the login request payload
type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=8"`
}

// RegisterRequest represents the registration request payload
type RegisterRequest struct {
	Email     string `json:"email" validate:"required,email"`
	Password  string `json:"password" validate:"required,min=8"`
	FirstName string `json:"first_name" validate:"required,min=2,max=50"`
	LastName  string `json:"last_name" validate:"required,min=2,max=50"`
}

// RefreshTokenRequest represents the refresh token request
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// ChangePasswordRequest represents the change password request
type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" validate:"required"`
	NewPassword     string `json:"new_password" validate:"required,min=8"`
}

// ResetPasswordRequest represents the reset password request
type ResetPasswordRequest struct {
	Email string `json:"email" validate:"required,email"`
}

// ConfirmResetPasswordRequest represents the confirm reset password request
type ConfirmResetPasswordRequest struct {
	Token       string `json:"token" validate:"required"`
	NewPassword string `json:"new_password" validate:"required,min=8"`
}

// UpdateProfileRequest represents the update profile request
type UpdateProfileRequest struct {
	FirstName string `json:"first_name,omitempty" validate:"omitempty,min=2,max=50"`
	LastName  string `json:"last_name,omitempty" validate:"omitempty,min=2,max=50"`
}

// AuthResponse represents the authentication response
type AuthResponse struct {
	AccessToken  string   `json:"access_token"`
	RefreshToken string   `json:"refresh_token"`
	TokenType    string   `json:"token_type"`
	ExpiresIn    int64    `json:"expires_in"`
	User         UserInfo `json:"user"`
}

// UserInfo represents user information in responses
type UserInfo struct {
	ID            uuid.UUID  `json:"id"`
	Email         string     `json:"email"`
	FirstName     string     `json:"first_name"`
	LastName      string     `json:"last_name"`
	Role          string     `json:"role"`
	EmailVerified bool       `json:"email_verified"`
	CreatedAt     time.Time  `json:"created_at"`
	LastLoginAt   *time.Time `json:"last_login_at,omitempty"`
}

// TokenClaims represents JWT token claims
type TokenClaims struct {
	UserID    uuid.UUID `json:"user_id"`
	Email     string    `json:"email"`
	Role      string    `json:"role"`
	TokenType string    `json:"token_type"`
	ExpiresAt int64     `json:"exp"`
	IssuedAt  int64     `json:"iat"`
	Issuer    string    `json:"iss"`
}
