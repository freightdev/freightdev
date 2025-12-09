// internal/services/user.go
package services

import (
	"context"
	"net/http"
	"strings"

	"auth-service/internal/config"
	"auth-service/internal/repositories"
	"auth-service/internal/shared/errors"
	"auth-service/internal/shared/types"

	"github.com/google/uuid"
)

// UserServiceImpl implements the UserService interface
type UserServiceImpl struct {
	config       *config.Config
	userRepo     repositories.UserRepository
	tokenService TokenService
	emailService EmailService // We'll define this interface
}

// NewUserService creates a new user service
func NewUserService(
	config *config.Config,
	userRepo repositories.UserRepository,
	tokenService TokenService,
	emailService EmailService,
) UserService {
	return &UserServiceImpl{
		config:       config,
		userRepo:     userRepo,
		tokenService: tokenService,
		emailService: emailService,
	}
}

// Register creates a new user account
func (s *UserServiceImpl) Register(ctx context.Context, req *types.RegisterRequest) (*types.UserInfo, error) {
	// Check if user already exists
	exists, err := s.userRepo.ExistsByEmail(ctx, req.Email)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, errors.ErrUserAlreadyExists()
	}

	// Create new user
	user := &domain.User{
		Email:         strings.ToLower(strings.TrimSpace(req.Email)),
		FirstName:     strings.TrimSpace(req.FirstName),
		LastName:      strings.TrimSpace(req.LastName),
		Role:          domain.RoleUser,
		Status:        domain.UserStatusPending, // Requires email verification
		EmailVerified: false,
	}

	// Set password
	if err := user.SetPassword(req.Password); err != nil {
		return nil, errors.ErrInternalServer()
	}

	// Save user
	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}

	// Generate email verification token
	verificationToken, err := s.tokenService.GenerateVerificationToken(ctx, user.ID)
	if err != nil {
		// User created but verification email failed - log this
		// In production, you might want to queue this for retry
	} else {
		// Send verification email (non-blocking)
		go func() {
			_ = s.emailService.SendVerificationEmail(context.Background(), user.Email, verificationToken)
		}()
	}

	return &types.UserInfo{
		ID:            user.ID,
		Email:         user.Email,
		FirstName:     user.FirstName,
		LastName:      user.LastName,
		Role:          string(user.Role),
		EmailVerified: user.EmailVerified,
		CreatedAt:     user.CreatedAt,
		LastLoginAt:   user.LastLoginAt,
	}, nil
}

// GetProfile retrieves user profile information
func (s *UserServiceImpl) GetProfile(ctx context.Context, userID uuid.UUID) (*types.UserInfo, error) {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	return &types.UserInfo{
		ID:            user.ID,
		Email:         user.Email,
		FirstName:     user.FirstName,
		LastName:      user.LastName,
		Role:          string(user.Role),
		EmailVerified: user.EmailVerified,
		CreatedAt:     user.CreatedAt,
		LastLoginAt:   user.LastLoginAt,
	}, nil
}

// UpdateProfile updates user profile information
func (s *UserServiceImpl) UpdateProfile(ctx context.Context, userID uuid.UUID, req *types.UpdateProfileRequest) (*types.UserInfo, error) {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Update fields
	if req.FirstName != "" {
		user.FirstName = strings.TrimSpace(req.FirstName)
	}
	if req.LastName != "" {
		user.LastName = strings.TrimSpace(req.LastName)
	}

	// Save changes
	if err := s.userRepo.Update(ctx, user); err != nil {
		return nil, err
	}

	return &types.UserInfo{
		ID:            user.ID,
		Email:         user.Email,
		FirstName:     user.FirstName,
		LastName:      user.LastName,
		Role:          string(user.Role),
		EmailVerified: user.EmailVerified,
		CreatedAt:     user.CreatedAt,
		LastLoginAt:   user.LastLoginAt,
	}, nil
}

// ChangePassword changes a user's password
func (s *UserServiceImpl) ChangePassword(ctx context.Context, userID uuid.UUID, req *types.ChangePasswordRequest) error {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return err
	}

	// Verify current password
	if !user.CheckPassword(req.CurrentPassword) {
		return errors.ErrInvalidCredentials()
	}

	// Set new password
	if err := user.SetPassword(req.NewPassword); err != nil {
		return errors.ErrInternalServer()
	}

	// Save changes
	return s.userRepo.Update(ctx, user)
}

// RequestPasswordReset initiates a password reset flow
func (s *UserServiceImpl) RequestPasswordReset(ctx context.Context, req *types.ResetPasswordRequest) error {
	user, err := s.userRepo.GetByEmail(ctx, req.Email)
	if err != nil {
		// Don't reveal if user exists or not
		return nil
	}

	// Generate reset token
	resetToken, err := s.tokenService.GenerateResetToken(ctx, user.ID)
	if err != nil {
		return err
	}

	// Send reset email (non-blocking)
	go func() {
		_ = s.emailService.SendPasswordResetEmail(context.Background(), user.Email, resetToken)
	}()

	return nil
}

// ConfirmPasswordReset completes the password reset flow
func (s *UserServiceImpl) ConfirmPasswordReset(ctx context.Context, req *types.ConfirmResetPasswordRequest) error {
	// Validate reset token
	claims, err := s.tokenService.ValidateToken(ctx, req.Token, domain.TokenTypeResetPassword)
	if err != nil {
		return err
	}

	// Get user
	user, err := s.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		return err
	}

	// Set new password
	if err := user.SetPassword(req.NewPassword); err != nil {
		return errors.ErrInternalServer()
	}

	// Save changes
	if err := s.userRepo.Update(ctx, user); err != nil {
		return err
	}

	// Blacklist the reset token to prevent reuse
	return s.tokenService.BlacklistToken(ctx, req.Token, claims.ExpiresAt)
}

// VerifyEmail verifies a user's email address
func (s *UserServiceImpl) VerifyEmail(ctx context.Context, token string) error {
	// Validate verification token
	claims, err := s.tokenService.ValidateToken(ctx, token, domain.TokenTypeEmailVerification)
	if err != nil {
		return err
	}

	// Get user
	user, err := s.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		return err
	}

	// Update email verification status
	user.EmailVerified = true
	user.Status = domain.UserStatusActive

	if err := s.userRepo.Update(ctx, user); err != nil {
		return err
	}

	// Blacklist the verification token to prevent reuse
	return s.tokenService.BlacklistToken(ctx, token, claims.ExpiresAt)
}

// ResendVerification resends email verification
func (s *UserServiceImpl) ResendVerification(ctx context.Context, email string) error {
	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return err
	}

	if user.EmailVerified {
		return errors.NewAppError(errors.ErrCodeValidationFailed, "Email already verified", http.StatusBadRequest)
	}

	// Generate new verification token
	verificationToken, err := s.tokenService.GenerateVerificationToken(ctx, user.ID)
	if err != nil {
		return err
	}

	// Send verification email (non-blocking)
	go func() {
		_ = s.emailService.SendVerificationEmail(context.Background(), user.Email, verificationToken)
	}()

	return nil
}

// EmailService interface for email operations
type EmailService interface {
	SendVerificationEmail(ctx context.Context, email, token string) error
	SendPasswordResetEmail(ctx context.Context, email, token string) error
}
