// internal/application/services/user_application_service.go
package services

import (
	"context"
	"time"
	"user_service/internal/application/dto/requests"
	"user_service/internal/application/dto/responses"
	"user_service/internal/domain/entities"
	"user_service/internal/domain/repositories"
	"user_service/internal/domain/services"
	"user_service/internal/shared/errors"
	"user_service/internal/shared/logger"

	"github.com/google/uuid"
)

type UserApplicationService interface {
	CreateUser(ctx context.Context, req *requests.CreateUserRequest) (*responses.CreateUserResponse, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (*responses.UserResponse, error)
	GetUserByEmail(ctx context.Context, email string) (*responses.UserResponse, error)
	GetUserByUsername(ctx context.Context, username string) (*responses.UserResponse, error)
	UpdateUser(ctx context.Context, id uuid.UUID, req *requests.UpdateUserRequest) (*responses.UserResponse, error)
	ChangePassword(ctx context.Context, id uuid.UUID, req *requests.ChangePasswordRequest) error
	DeleteUser(ctx context.Context, id uuid.UUID) error
	ListUsers(ctx context.Context, req *requests.ListUsersRequest) (*responses.ListUsersResponse, error)
	ActivateUser(ctx context.Context, id uuid.UUID) (*responses.UserResponse, error)
	SuspendUser(ctx context.Context, id uuid.UUID) (*responses.UserResponse, error)
	UpdateProfile(ctx context.Context, userID uuid.UUID, req *requests.UpdateProfileRequest) (*responses.ProfileResponse, error)
}

type userApplicationService struct {
	userRepo      repositories.UserRepository
	profileRepo   repositories.ProfileRepository
	domainService services.UserDomainService
	logger        logger.Logger
}

func NewUserApplicationService(
	userRepo repositories.UserRepository,
	profileRepo repositories.ProfileRepository,
	domainService services.UserDomainService,
	logger logger.Logger,
) UserApplicationService {
	return &userApplicationService{
		userRepo:      userRepo,
		profileRepo:   profileRepo,
		domainService: domainService,
		logger:        logger,
	}
}

func (s *userApplicationService) CreateUser(ctx context.Context, req *requests.CreateUserRequest) (*responses.CreateUserResponse, error) {
	s.logger.Info("Creating new user", zap.String("email", req.Email), zap.String("username", req.Username))

	// Validate request
	if err := req.Validate(); err != nil {
		return nil, err
	}

	// Domain validation (uniqueness checks)
	if err := s.domainService.ValidateUserCreation(ctx, req.Email, req.Username); err != nil {
		return nil, errors.WrapError(err, "user validation failed")
	}

	// Create user entity
	user, err := entities.NewUser(req.Email, req.Username, req.Password)
	if err != nil {
		return nil, errors.NewInternalError("failed to create user entity", err)
	}

	// Create profile entity
	profile := entities.NewProfile(user.ID, req.FirstName, req.LastName)

	// Start transaction-like operation (repositories should handle transactions)
	if err := s.userRepo.Create(ctx, user); err != nil {
		s.logger.Error("Failed to create user", zap.Error(err), zap.String("email", req.Email))
		return nil, errors.NewInternalError("failed to create user", err)
	}

	if err := s.profileRepo.Create(ctx, profile); err != nil {
		s.logger.Error("Failed to create profile", zap.Error(err), zap.String("user_id", user.ID.String()))
		// In a real implementation, you'd rollback the user creation
		return nil, errors.NewInternalError("failed to create user profile", err)
	}

	// Attach profile to user for response
	user.Profile = profile

	s.logger.Info("User created successfully", zap.String("user_id", user.ID.String()))

	return &responses.CreateUserResponse{
		User:    responses.MapUserToResponse(user),
		Message: "User created successfully",
	}, nil
}

func (s *userApplicationService) GetUserByID(ctx context.Context, id uuid.UUID) (*responses.UserResponse, error) {
	user, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		if errors.Is(err, entities.ErrUserNotFound) {
			return nil, errors.NewNotFoundError("user")
		}
		return nil, errors.NewInternalError("failed to get user", err)
	}

	// Load profile
	profile, err := s.profileRepo.GetByUserID(ctx, user.ID)
	if err != nil && !errors.Is(err, entities.ErrProfileNotFound) {
		s.logger.Warn("Failed to load user profile", zap.Error(err), zap.String("user_id", user.ID.String()))
	} else if profile != nil {
		user.Profile = profile
	}

	response := responses.MapUserToResponse(user)
	return &response, nil
}

func (s *userApplicationService) GetUserByEmail(ctx context.Context, email string) (*responses.UserResponse, error) {
	if err := validators.ValidateEmail(email); err != nil {
		return nil, err
	}

	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, entities.ErrUserNotFound) {
			return nil, errors.NewNotFoundError("user")
		}
		return nil, errors.NewInternalError("failed to get user", err)
	}

	// Load profile
	profile, err := s.profileRepo.GetByUserID(ctx, user.ID)
	if err != nil && !errors.Is(err, entities.ErrProfileNotFound) {
		s.logger.Warn("Failed to load user profile", zap.Error(err), zap.String("user_id", user.ID.String()))
	} else if profile != nil {
		user.Profile = profile
	}

	response := responses.MapUserToResponse(user)
	return &response, nil
}

func (s *userApplicationService) UpdateUser(ctx context.Context, id uuid.UUID, req *requests.UpdateUserRequest) (*responses.UserResponse, error) {
	if err := req.Validate(); err != nil {
		return nil, err
	}

	user, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		if errors.Is(err, entities.ErrUserNotFound) {
			return nil, errors.NewNotFoundError("user")
		}
		return nil, errors.NewInternalError("failed to get user", err)
	}

	// Check for uniqueness if email/username is being updated
	if req.Email != nil && *req.Email != user.Email {
		exists, err := s.userRepo.ExistsByEmail(ctx, *req.Email)
		if err != nil {
			return nil, errors.NewInternalError("failed to check email uniqueness", err)
		}
		if exists {
			return nil, errors.NewConflictError("email already exists")
		}
		user.Email = *req.Email
	}

	if req.Username != nil && *req.Username != user.Username {
		exists, err := s.userRepo.ExistsByUsername(ctx, *req.Username)
		if err != nil {
			return nil, errors.NewInternalError("failed to check username uniqueness", err)
		}
		if exists {
			return nil, errors.NewConflictError("username already exists")
		}
		user.Username = *req.Username
	}

	user.UpdatedAt = time.Now().UTC()

	if err := s.userRepo.Update(ctx, user); err != nil {
		return nil, errors.NewInternalError("failed to update user", err)
	}

	response := responses.MapUserToResponse(user)
	return &response, nil
}

func (s *userApplicationService) ChangePassword(ctx context.Context, id uuid.UUID, req *requests.ChangePasswordRequest) error {
	if err := req.Validate(); err != nil {
		return err
	}

	user, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		if errors.Is(err, entities.ErrUserNotFound) {
			return errors.NewNotFoundError("user")
		}
		return errors.NewInternalError("failed to get user", err)
	}

	// Validate current password
	if err := user.ValidatePassword(req.CurrentPassword); err != nil {
		return errors.NewUnauthorizedError("invalid current password")
	}

	// Create new user entity with new password (to hash it)
	newUser, err := entities.NewUser(user.Email, user.Username, req.NewPassword)
	if err != nil {
		return errors.NewInternalError("failed to hash new password", err)
	}

	// Update only the password hash
	user.PasswordHash = newUser.PasswordHash
	user.UpdatedAt = time.Now().UTC()

	if err := s.userRepo.Update(ctx, user); err != nil {
		return errors.NewInternalError("failed to update password", err)
	}

	s.logger.Info("Password changed successfully", zap.String("user_id", user.ID.String()))
	return nil
}

func (s *userApplicationService) ActivateUser(ctx context.Context, id uuid.UUID) (*responses.UserResponse, error) {
	user, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		if errors.Is(err, entities.ErrUserNotFound) {
			return nil, errors.NewNotFoundError("user")
		}
		return nil, errors.NewInternalError("failed to get user", err)
	}

	if err := user.Activate(); err != nil {
		return nil, errors.WrapError(err, "failed to activate user")
	}

	if err := s.userRepo.Update(ctx, user); err != nil {
		return nil, errors.NewInternalError("failed to update user status", err)
	}

	response := responses.MapUserToResponse(user)
	return &response, nil
}

func (s *userApplicationService) ListUsers(ctx context.Context, req *requests.ListUsersRequest) (*responses.ListUsersResponse, error) {
	if err := req.Validate(); err != nil {
		return nil, err
	}

	// Set defaults
	limit := 10
	if req.Limit != nil {
		limit = *req.Limit
	}

	offset := 0
	if req.Offset != nil {
		offset = *req.Offset
	}

	// Build filter
	filter := repositories.UserFilter{
		Limit:     limit,
		Offset:    offset,
		SortBy:    "created_at",
		SortOrder: "desc",
	}

	if req.Status != nil {
		status := entities.UserStatus(*req.Status)
		filter.Status = &status
	}
	if req.Email != nil {
		filter.Email = req.Email
	}
	if req.Username != nil {
		filter.Username = req.Username
	}
	if req.SearchTerm != nil {
		filter.SearchTerm = req.SearchTerm
	}
	if req.CreatedAfter != nil {
		filter.CreatedAfter = req.CreatedAfter
	}
	if req.CreatedBefore != nil {
		filter.CreatedBefore = req.CreatedBefore
	}
	if req.SortBy != nil {
		filter.SortBy = *req.SortBy
	}
	if req.SortOrder != nil {
		filter.SortOrder = *req.SortOrder
	}

	users, err := s.userRepo.List(ctx, filter)
	if err != nil {
		return nil, errors.NewInternalError("failed to list users", err)
	}

	total, err := s.userRepo.Count(ctx, filter)
	if err != nil {
		return nil, errors.NewInternalError("failed to count users", err)
	}

	return &responses.ListUsersResponse{
		Users:   responses.MapUsersToResponse(users),
		Total:   total,
		Limit:   limit,
		Offset:  offset,
		HasMore: int64(offset+limit) < total,
	}, nil
}
