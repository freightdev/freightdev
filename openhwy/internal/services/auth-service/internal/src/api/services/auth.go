// internal/services/auth.go
package services

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"auth-service/internal/config"
	"auth-service/internal/repositories"
	"auth-service/internal/shared/errors"
	"auth-service/internal/shared/types"

	"github.com/google/uuid"
)

// AuthServiceImpl implements the AuthService interface
type AuthServiceImpl struct {
	config           *config.Config
	userRepo         repositories.UserRepository
	sessionRepo      repositories.SessionRepository
	loginAttemptRepo repositories.LoginAttemptRepository
	tokenService     TokenService
}

// NewAuthService creates a new authentication service
func NewAuthService(
	config *config.Config,
	userRepo repositories.UserRepository,
	sessionRepo repositories.SessionRepository,
	loginAttemptRepo repositories.LoginAttemptRepository,
	tokenService TokenService,
) AuthService {
	return &AuthServiceImpl{
		config:           config,
		userRepo:         userRepo,
		sessionRepo:      sessionRepo,
		loginAttemptRepo: loginAttemptRepo,
		tokenService:     tokenService,
	}
}

// Login authenticates a user and returns tokens
func (s *AuthServiceImpl) Login(ctx context.Context, req *types.LoginRequest) (*types.AuthResponse, error) {
	// Check if user is locked out
	locked, lockUntil, err := s.loginAttemptRepo.IsLocked(ctx, req.Email)
	if err != nil {
		return nil, err
	}
	if locked {
		return nil, errors.NewAppErrorWithDetails(
			errors.ErrCodeUnauthorized,
			"Account temporarily locked due to too many failed attempts",
			fmt.Sprintf("Try again after %v", lockUntil.Format(time.RFC3339)),
			http.StatusTooManyRequests,
		)
	}

	// Get user by email
	user, err := s.userRepo.GetByEmail(ctx, req.Email)
	if err != nil {
		// Record failed attempt even if user doesn't exist
		_ = s.loginAttemptRepo.RecordAttempt(ctx, req.Email, getIPFromContext(ctx), false)
		return nil, errors.ErrInvalidCredentials()
	}

	// Check if user is active
	if !user.IsActive() {
		_ = s.loginAttemptRepo.RecordAttempt(ctx, req.Email, getIPFromContext(ctx), false)
		return nil, errors.NewAppError(errors.ErrCodeForbidden, "Account is not active", http.StatusForbidden)
	}

	// Verify password
	if !user.CheckPassword(req.Password) {
		_ = s.loginAttemptRepo.RecordAttempt(ctx, req.Email, getIPFromContext(ctx), false)
		return nil, errors.ErrInvalidCredentials()
	}

	// Record successful attempt and clear any previous failed attempts
	_ = s.loginAttemptRepo.RecordAttempt(ctx, req.Email, getIPFromContext(ctx), true)
	_ = s.loginAttemptRepo.ClearAttempts(ctx, req.Email)

	// Update last login time
	_ = s.userRepo.UpdateLastLogin(ctx, user.ID)

	// Generate token pair
	authResponse, err := s.tokenService.GenerateTokenPair(ctx, user)
	if err != nil {
		return nil, err
	}

	// Create session record
	session := &domain.Session{
		ID:        uuid.New(),
		UserID:    user.ID,
		Token:     authResponse.RefreshToken,
		ExpiresAt: time.Now().Add(s.config.JWT.RefreshExpiry),
		IPAddress: getIPFromContext(ctx),
		UserAgent: getUserAgentFromContext(ctx),
	}

	if err := s.sessionRepo.Create(ctx, session); err != nil {
		// Log error but don't fail the login
		// In production, you might want to handle this differently
	}

	return authResponse, nil
}

// RefreshToken refreshes an access token using a refresh token
func (s *AuthServiceImpl) RefreshToken(ctx context.Context, req *types.RefreshTokenRequest) (*types.AuthResponse, error) {
	// Validate refresh token
	claims, err := s.tokenService.ValidateToken(ctx, req.RefreshToken, domain.TokenTypeRefresh)
	if err != nil {
		return nil, err
	}

	// Get user
	user, err := s.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		return nil, err
	}

	// Check if user is still active
	if !user.IsActive() {
		return nil, errors.NewAppError(errors.ErrCodeForbidden, "Account is not active", http.StatusForbidden)
	}

	// Verify session exists and is valid
	session, err := s.sessionRepo.GetByToken(ctx, req.RefreshToken)
	if err != nil {
		return nil, errors.ErrInvalidToken()
	}

	if !session.IsValid() {
		return nil, errors.ErrTokenExpired()
	}

	// Generate new token pair
	return s.tokenService.GenerateTokenPair(ctx, user)
}

// Logout logs out a user from a specific session
func (s *AuthServiceImpl) Logout(ctx context.Context, userID uuid.UUID, sessionToken string) error {
	// Find and revoke the session
	session, err := s.sessionRepo.GetByToken(ctx, sessionToken)
	if err != nil {
		return nil // Session might not exist, that's okay
	}

	if session.UserID != userID {
		return errors.ErrForbidden()
	}

	session.Revoke()
	return s.sessionRepo.Update(ctx, session)
}

// LogoutAll logs out a user from all sessions
func (s *AuthServiceImpl) LogoutAll(ctx context.Context, userID uuid.UUID) error {
	return s.sessionRepo.RevokeAllByUserID(ctx, userID)
}

// ValidateToken validates an access token
func (s *AuthServiceImpl) ValidateToken(ctx context.Context, token string) (*types.TokenClaims, error) {
	return s.tokenService.ValidateToken(ctx, token, domain.TokenTypeAccess)
}

// RevokeToken revokes a token by adding it to the blacklist
func (s *AuthServiceImpl) RevokeToken(ctx context.Context, token string) error {
	claims, err := s.tokenService.ValidateToken(ctx, token, "")
	if err != nil {
		return err
	}

	// Extract JTI from token (you'll need to parse the token again to get the header)
	// For now, we'll use the token itself as the identifier
	return s.tokenService.BlacklistToken(ctx, token, claims.ExpiresAt)
}

// Helper functions to extract context values (these would be set by middleware)
func getIPFromContext(ctx context.Context) string {
	if ip, ok := ctx.Value("client_ip").(string); ok {
		return ip
	}
	return "unknown"
}

func getUserAgentFromContext(ctx context.Context) string {
	if ua, ok := ctx.Value("user_agent").(string); ok {
		return ua
	}
	return "unknown"
}
