// internal/services/token.go
package services

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"time"

	"auth-service/internal/config"
	"auth-service/internal/repositories"
	"auth-service/internal/shared/errors"
	"auth-service/internal/shared/types"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// TokenServiceImpl implements the TokenService interface
type TokenServiceImpl struct {
	config             *config.Config
	tokenBlacklistRepo repositories.TokenBlacklistRepository
}

// NewTokenService creates a new token service
func NewTokenService(
	config *config.Config,
	tokenBlacklistRepo repositories.TokenBlacklistRepository,
) TokenService {
	return &TokenServiceImpl{
		config:             config,
		tokenBlacklistRepo: tokenBlacklistRepo,
	}
}

// GenerateTokenPair generates both access and refresh tokens
func (s *TokenServiceImpl) GenerateTokenPair(ctx context.Context, user *domain.User) (*types.AuthResponse, error) {
	accessToken, err := s.GenerateAccessToken(ctx, user)
	if err != nil {
		return nil, err
	}

	refreshToken, err := s.GenerateRefreshToken(ctx, user)
	if err != nil {
		return nil, err
	}

	return &types.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    int64(s.config.JWT.AccessExpiry.Seconds()),
		User: types.UserInfo{
			ID:            user.ID,
			Email:         user.Email,
			FirstName:     user.FirstName,
			LastName:      user.LastName,
			Role:          string(user.Role),
			EmailVerified: user.EmailVerified,
			CreatedAt:     user.CreatedAt,
			LastLoginAt:   user.LastLoginAt,
		},
	}, nil
}

// GenerateAccessToken generates an access token
func (s *TokenServiceImpl) GenerateAccessToken(ctx context.Context, user *domain.User) (string, error) {
	now := time.Now()
	expiresAt := now.Add(s.config.JWT.AccessExpiry)

	claims := &types.TokenClaims{
		UserID:    user.ID,
		Email:     user.Email,
		Role:      string(user.Role),
		TokenType: string(domain.TokenTypeAccess),
		ExpiresAt: expiresAt.Unix(),
		IssuedAt:  now.Unix(),
		Issuer:    s.config.JWT.Issuer,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	token.Header["jti"] = generateJTI()

	return token.SignedString([]byte(s.config.JWT.AccessSecret))
}

// GenerateRefreshToken generates a refresh token
func (s *TokenServiceImpl) GenerateRefreshToken(ctx context.Context, user *domain.User) (string, error) {
	now := time.Now()
	expiresAt := now.Add(s.config.JWT.RefreshExpiry)

	claims := &types.TokenClaims{
		UserID:    user.ID,
		Email:     user.Email,
		Role:      string(user.Role),
		TokenType: string(domain.TokenTypeRefresh),
		ExpiresAt: expiresAt.Unix(),
		IssuedAt:  now.Unix(),
		Issuer:    s.config.JWT.Issuer,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	token.Header["jti"] = generateJTI()

	return token.SignedString([]byte(s.config.JWT.RefreshSecret))
}

// GenerateResetToken generates a password reset token
func (s *TokenServiceImpl) GenerateResetToken(ctx context.Context, userID uuid.UUID) (string, error) {
	now := time.Now()
	expiresAt := now.Add(s.config.JWT.ResetExpiry)

	claims := &types.TokenClaims{
		UserID:    userID,
		TokenType: string(domain.TokenTypeResetPassword),
		ExpiresAt: expiresAt.Unix(),
		IssuedAt:  now.Unix(),
		Issuer:    s.config.JWT.Issuer,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	token.Header["jti"] = generateJTI()

	return token.SignedString([]byte(s.config.JWT.AccessSecret))
}

// GenerateVerificationToken generates an email verification token
func (s *TokenServiceImpl) GenerateVerificationToken(ctx context.Context, userID uuid.UUID) (string, error) {
	now := time.Now()
	expiresAt := now.Add(s.config.JWT.VerificationExpiry)

	claims := &types.TokenClaims{
		UserID:    userID,
		TokenType: string(domain.TokenTypeEmailVerification),
		ExpiresAt: expiresAt.Unix(),
		IssuedAt:  now.Unix(),
		Issuer:    s.config.JWT.Issuer,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	token.Header["jti"] = generateJTI()

	return token.SignedString([]byte(s.config.JWT.AccessSecret))
}

// ValidateToken validates a JWT token
func (s *TokenServiceImpl) ValidateToken(ctx context.Context, tokenString string, tokenType domain.TokenType) (*types.TokenClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &types.TokenClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.ErrInvalidToken()
		}

		// Get the secret based on token type
		claims, ok := token.Claims.(*types.TokenClaims)
		if !ok {
			return nil, errors.ErrInvalidToken()
		}

		switch domain.TokenType(claims.TokenType) {
		case domain.TokenTypeAccess, domain.TokenTypeResetPassword, domain.TokenTypeEmailVerification:
			return []byte(s.config.JWT.AccessSecret), nil
		case domain.TokenTypeRefresh:
			return []byte(s.config.JWT.RefreshSecret), nil
		default:
			return nil, errors.ErrInvalidToken()
		}
	})

	if err != nil {
		if ve, ok := err.(*jwt.ValidationError); ok {
			if ve.Errors&jwt.ValidationErrorExpired != 0 {
				return nil, errors.ErrTokenExpired()
			}
		}
		return nil, errors.ErrInvalidToken()
	}

	if !token.Valid {
		return nil, errors.ErrInvalidToken()
	}

	claims, ok := token.Claims.(*types.TokenClaims)
	if !ok {
		return nil, errors.ErrInvalidToken()
	}

	// Validate token type if specified
	if tokenType != "" && domain.TokenType(claims.TokenType) != tokenType {
		return nil, errors.ErrInvalidToken()
	}

	// Check if token is blacklisted
	if jti, exists := token.Header["jti"]; exists {
		if jtiStr, ok := jti.(string); ok {
			isBlacklisted, err := s.IsTokenBlacklisted(ctx, jtiStr)
			if err != nil {
				return nil, err
			}
			if isBlacklisted {
				return nil, errors.ErrInvalidToken()
			}
		}
	}

	return claims, nil
}

// BlacklistToken adds a token to the blacklist
func (s *TokenServiceImpl) BlacklistToken(ctx context.Context, tokenID string, expiresAt int64) error {
	expiryTime := time.Unix(expiresAt, 0)
	return s.tokenBlacklistRepo.Add(ctx, tokenID, expiryTime)
}

// IsTokenBlacklisted checks if a token is blacklisted
func (s *TokenServiceImpl) IsTokenBlacklisted(ctx context.Context, tokenID string) (bool, error) {
	return s.tokenBlacklistRepo.IsBlacklisted(ctx, tokenID)
}

// generateJTI generates a unique JWT ID
func generateJTI() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}
