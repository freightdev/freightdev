// internal/services/interfaces.go
package services

import (
	"context"

	"auth-service/internal/shared/types"

	"github.com/google/uuid"
)

// AuthService defines the authentication service interface
type AuthService interface {
	Login(ctx context.Context, req *types.LoginRequest) (*types.AuthResponse, error)
	RefreshToken(ctx context.Context, req *types.RefreshTokenRequest) (*types.AuthResponse, error)
	Logout(ctx context.Context, userID uuid.UUID, sessionToken string) error
	LogoutAll(ctx context.Context, userID uuid.UUID) error
	ValidateToken(ctx context.Context, token string) (*types.TokenClaims, error)
	RevokeToken(ctx context.Context, token string) error
}

// UserService defines the user management service interface
type UserService interface {
	Register(ctx context.Context, req *types.RegisterRequest) (*types.UserInfo, error)
	GetProfile(ctx context.Context, userID uuid.UUID) (*types.UserInfo, error)
	UpdateProfile(ctx context.Context, userID uuid.UUID, req *types.UpdateProfileRequest) (*types.UserInfo, error)
	ChangePassword(ctx context.Context, userID uuid.UUID, req *types.ChangePasswordRequest) error
	RequestPasswordReset(ctx context.Context, req *types.ResetPasswordRequest) error
	ConfirmPasswordReset(ctx context.Context, req *types.ConfirmResetPasswordRequest) error
	VerifyEmail(ctx context.Context, token string) error
	ResendVerification(ctx context.Context, email string) error
}

// TokenService defines the token management service interface
type TokenService interface {
	GenerateTokenPair(ctx context.Context, user *domain.User) (*types.AuthResponse, error)
	GenerateAccessToken(ctx context.Context, user *domain.User) (string, error)
	GenerateRefreshToken(ctx context.Context, user *domain.User) (string, error)
	GenerateResetToken(ctx context.Context, userID uuid.UUID) (string, error)
	GenerateVerificationToken(ctx context.Context, userID uuid.UUID) (string, error)
	ValidateToken(ctx context.Context, token string, tokenType domain.TokenType) (*types.TokenClaims, error)
	BlacklistToken(ctx context.Context, tokenID string, expiresAt int64) error
	IsTokenBlacklisted(ctx context.Context, tokenID string) (bool, error)
}
