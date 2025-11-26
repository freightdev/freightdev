// internal/application/dto/requests/user_requests.go
package requests

import (
	"time"
	"user_service/internal/shared/errors"
	"user_service/internal/shared/validators"
)

type CreateUserRequest struct {
	Email     string `json:"email" binding:"required"`
	Username  string `json:"username" binding:"required"`
	Password  string `json:"password" binding:"required"`
	FirstName string `json:"first_name" binding:"required"`
	LastName  string `json:"last_name" binding:"required"`
}

func (r *CreateUserRequest) Validate() *errors.AppError {
	result := &validators.ValidationResult{}

	result.AddError(validators.ValidateEmail(r.Email))
	result.AddError(validators.ValidateUsername(r.Username))
	result.AddError(validators.ValidatePassword(r.Password))
	result.AddError(validators.ValidateName(r.FirstName, "first name"))
	result.AddError(validators.ValidateName(r.LastName, "last name"))

	return result.ToAppError()
}

type UpdateUserRequest struct {
	Email    *string `json:"email,omitempty"`
	Username *string `json:"username,omitempty"`
}

func (r *UpdateUserRequest) Validate() *errors.AppError {
	result := &validators.ValidationResult{}

	if r.Email != nil {
		result.AddError(validators.ValidateEmail(*r.Email))
	}
	if r.Username != nil {
		result.AddError(validators.ValidateUsername(*r.Username))
	}

	return result.ToAppError()
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" binding:"required"`
	NewPassword     string `json:"new_password" binding:"required"`
}

func (r *ChangePasswordRequest) Validate() *errors.AppError {
	result := &validators.ValidationResult{}

	result.AddError(validators.ValidateRequired(r.CurrentPassword, "current password"))
	result.AddError(validators.ValidatePassword(r.NewPassword))

	return result.ToAppError()
}

type UpdateProfileRequest struct {
	FirstName   *string    `json:"first_name,omitempty"`
	LastName    *string    `json:"last_name,omitempty"`
	Bio         *string    `json:"bio,omitempty"`
	Location    *string    `json:"location,omitempty"`
	Website     *string    `json:"website,omitempty"`
	DateOfBirth *time.Time `json:"date_of_birth,omitempty"`
}

func (r *UpdateProfileRequest) Validate() *errors.AppError {
	result := &validators.ValidationResult{}

	if r.FirstName != nil {
		result.AddError(validators.ValidateName(*r.FirstName, "first name"))
	}
	if r.LastName != nil {
		result.AddError(validators.ValidateName(*r.LastName, "last name"))
	}
	if r.Bio != nil {
		result.AddError(validators.ValidateMaxLength(*r.Bio, 500, "bio"))
	}
	if r.Location != nil {
		result.AddError(validators.ValidateMaxLength(*r.Location, 100, "location"))
	}
	if r.Website != nil {
		result.AddError(validators.ValidateURL(*r.Website, "website"))
	}

	return result.ToAppError()
}

type ListUsersRequest struct {
	Status        *string    `form:"status"`
	Email         *string    `form:"email"`
	Username      *string    `form:"username"`
	SearchTerm    *string    `form:"search"`
	CreatedAfter  *time.Time `form:"created_after"`
	CreatedBefore *time.Time `form:"created_before"`
	SortBy        *string    `form:"sort_by"`
	SortOrder     *string    `form:"sort_order"`
	Limit         *int       `form:"limit"`
	Offset        *int       `form:"offset"`
}

func (r *ListUsersRequest) Validate() *errors.AppError {
	result := &validators.ValidationResult{}

	if r.SortBy != nil {
		validSortFields := map[string]bool{
			"created_at": true, "updated_at": true, "last_login_at": true,
			"email": true, "username": true,
		}
		if !validSortFields[*r.SortBy] {
			result.AddError(errors.NewValidationError("invalid sort field"))
		}
	}

	if r.SortOrder != nil {
		if *r.SortOrder != "asc" && *r.SortOrder != "desc" {
			result.AddError(errors.NewValidationError("sort order must be 'asc' or 'desc'"))
		}
	}

	if r.Limit != nil && (*r.Limit < 1 || *r.Limit > 100) {
		result.AddError(errors.NewValidationError("limit must be between 1 and 100"))
	}

	if r.Offset != nil && *r.Offset < 0 {
		result.AddError(errors.NewValidationError("offset must be non-negative"))
	}

	return result.ToAppError()
}
