// internal/domain/services/user_domain_service.go (same file for brevity)
package services

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"user_service/internal/domain/entities"
	"user_service/internal/domain/repositories"
)

// UserDomainService handles complex business rules that span multiple entities
type UserDomainService interface {
	ValidateUserCreation(ctx context.Context, email, username string) error
	CanUserBeDeleted(ctx context.Context, userID uuid.UUID) error
	GenerateUsername(ctx context.Context, email string) (string, error)
}

type userDomainService struct {
	userRepo    repositories.UserRepository
	profileRepo repositories.ProfileRepository
}

func NewUserDomainService(userRepo repositories.UserRepository, profileRepo repositories.ProfileRepository) UserDomainService {
	return &userDomainService{
		userRepo:    userRepo,
		profileRepo: profileRepo,
	}
}

func (s *userDomainService) ValidateUserCreation(ctx context.Context, email, username string) error {
	// Check email uniqueness
	exists, err := s.userRepo.ExistsByEmail(ctx, email)
	if err != nil {
		return err
	}
	if exists {
		return entities.ErrUserAlreadyExists
	}

	// Check username uniqueness
	exists, err = s.userRepo.ExistsByUsername(ctx, username)
	if err != nil {
		return err
	}
	if exists {
		return entities.ErrUserAlreadyExists
	}

	return nil
}

func (s *userDomainService) CanUserBeDeleted(ctx context.Context, userID uuid.UUID) error {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return err
	}

	// Business rule: Can't delete active users that logged in recently
	if user.Status == entities.UserStatusActive && user.LastLoginAt != nil {
		// Add your business logic here
		// For example, check if last login was within last 30 days
	}

	return nil
}

func (s *userDomainService) GenerateUsername(ctx context.Context, email string) (string, error) {
	// Extract base username from email
	baseUsername := strings.Split(email, "@")[0]

	// Check if it's available
	exists, err := s.userRepo.ExistsByUsername(ctx, baseUsername)
	if err != nil {
		return "", err
	}

	if !exists {
		return baseUsername, nil
	}

	// Generate alternatives
	for i := 1; i <= 100; i++ {
		candidate := fmt.Sprintf("%s%d", baseUsername, i)
		exists, err := s.userRepo.ExistsByUsername(ctx, candidate)
		if err != nil {
			return "", err
		}
		if !exists {
			return candidate, nil
		}
	}

	return "", errors.New("unable to generate unique username")
}
