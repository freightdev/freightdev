// internal/application/dto/responses/user_responses.go (same file)
package responses

import (
	"time"
	"user_service/internal/domain/entities"

	"github.com/google/uuid"
)

type UserResponse struct {
	ID          uuid.UUID           `json:"id"`
	Email       string              `json:"email"`
	Username    string              `json:"username"`
	Status      entities.UserStatus `json:"status"`
	CreatedAt   time.Time           `json:"created_at"`
	UpdatedAt   time.Time           `json:"updated_at"`
	LastLoginAt *time.Time          `json:"last_login_at,omitempty"`
	Profile     *ProfileResponse    `json:"profile,omitempty"`
}

type ProfileResponse struct {
	ID          uuid.UUID  `json:"id"`
	UserID      uuid.UUID  `json:"user_id"`
	FirstName   string     `json:"first_name"`
	LastName    string     `json:"last_name"`
	FullName    string     `json:"full_name"`
	Avatar      *string    `json:"avatar,omitempty"`
	Bio         *string    `json:"bio,omitempty"`
	Location    *string    `json:"location,omitempty"`
	Website     *string    `json:"website,omitempty"`
	DateOfBirth *time.Time `json:"date_of_birth,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

type ListUsersResponse struct {
	Users   []UserResponse `json:"users"`
	Total   int64          `json:"total"`
	Limit   int            `json:"limit"`
	Offset  int            `json:"offset"`
	HasMore bool           `json:"has_more"`
}

type CreateUserResponse struct {
	User    UserResponse `json:"user"`
	Message string       `json:"message"`
}

type APIResponse[T any] struct {
	Success   bool      `json:"success"`
	Data      T         `json:"data,omitempty"`
	Message   string    `json:"message,omitempty"`
	RequestID string    `json:"request_id"`
	Timestamp time.Time `json:"timestamp"`
}

func NewSuccessResponse[T any](data T, message string, requestID string) APIResponse[T] {
	return APIResponse[T]{
		Success:   true,
		Data:      data,
		Message:   message,
		RequestID: requestID,
		Timestamp: time.Now().UTC(),
	}
}

func NewErrorResponse(message string, requestID string) APIResponse[interface{}] {
	return APIResponse[interface{}]{
		Success:   false,
		Message:   message,
		RequestID: requestID,
		Timestamp: time.Now().UTC(),
	}
}

// Mapper functions
func MapUserToResponse(user *entities.User) UserResponse {
	resp := UserResponse{
		ID:          user.ID,
		Email:       user.Email,
		Username:    user.Username,
		Status:      user.Status,
		CreatedAt:   user.CreatedAt,
		UpdatedAt:   user.UpdatedAt,
		LastLoginAt: user.LastLoginAt,
	}

	if user.Profile != nil {
		resp.Profile = MapProfileToResponse(user.Profile)
	}

	return resp
}

func MapProfileToResponse(profile *entities.Profile) *ProfileResponse {
	return &ProfileResponse{
		ID:          profile.ID,
		UserID:      profile.UserID,
		FirstName:   profile.FirstName,
		LastName:    profile.LastName,
		FullName:    profile.GetFullName(),
		Avatar:      profile.Avatar,
		Bio:         profile.Bio,
		Location:    profile.Location,
		Website:     profile.Website,
		DateOfBirth: profile.DateOfBirth,
		CreatedAt:   profile.CreatedAt,
		UpdatedAt:   profile.UpdatedAt,
	}
}

func MapUsersToResponse(users []*entities.User) []UserResponse {
	responses := make([]UserResponse, len(users))
	for i, user := range users {
		responses[i] = MapUserToResponse(user)
	}
	return responses
}
