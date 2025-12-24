// internal/shared/validators/validators.go
package validators

import (
	"regexp"
	"strings"
	"unicode"
	"user_service/internal/shared/errors"
)

var (
	emailRegex    = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	usernameRegex = regexp.MustCompile(`^[a-zA-Z0-9_]{3,30}$`)
)

func ValidateEmail(email string) *errors.AppError {
	if strings.TrimSpace(email) == "" {
		return errors.NewValidationError("email is required")
	}

	if !emailRegex.MatchString(email) {
		return errors.NewValidationError("invalid email format")
	}

	return nil
}

func ValidateUsername(username string) *errors.AppError {
	if strings.TrimSpace(username) == "" {
		return errors.NewValidationError("username is required")
	}

	if len(username) < 3 || len(username) > 30 {
		return errors.NewValidationError("username must be between 3 and 30 characters")
	}

	if !usernameRegex.MatchString(username) {
		return errors.NewValidationError("username can only contain letters, numbers, and underscores")
	}

	return nil
}

func ValidatePassword(password string) *errors.AppError {
	if strings.TrimSpace(password) == "" {
		return errors.NewValidationError("password is required")
	}

	if len(password) < 8 {
		return errors.NewValidationError("password must be at least 8 characters long")
	}

	var (
		hasUpper   = false
		hasLower   = false
		hasNumber  = false
		hasSpecial = false
	)

	for _, char := range password {
		switch {
		case unicode.IsUpper(char):
			hasUpper = true
		case unicode.IsLower(char):
			hasLower = true
		case unicode.IsDigit(char):
			hasNumber = true
		case unicode.IsPunct(char) || unicode.IsSymbol(char):
			hasSpecial = true
		}
	}

	if !hasUpper {
		return errors.NewValidationError("password must contain at least one uppercase letter")
	}
	if !hasLower {
		return errors.NewValidationError("password must contain at least one lowercase letter")
	}
	if !hasNumber {
		return errors.NewValidationError("password must contain at least one number")
	}
	if !hasSpecial {
		return errors.NewValidationError("password must contain at least one special character")
	}

	return nil
}

func ValidateRequired(value, fieldName string) *errors.AppError {
	if strings.TrimSpace(value) == "" {
		return errors.NewValidationError(fieldName + " is required")
	}
	return nil
}

func ValidateMaxLength(value string, maxLength int, fieldName string) *errors.AppError {
	if len(value) > maxLength {
		return errors.NewValidationError(fieldName + " must not exceed " + string(rune(maxLength)) + " characters")
	}
	return nil
}

func ValidateMinLength(value string, minLength int, fieldName string) *errors.AppError {
	if len(value) < minLength {
		return errors.NewValidationError(fieldName + " must be at least " + string(rune(minLength)) + " characters")
	}
	return nil
}

func ValidateName(name, fieldName string) *errors.AppError {
	if err := ValidateRequired(name, fieldName); err != nil {
		return err
	}

	if len(name) > 50 {
		return errors.NewValidationError(fieldName + " must not exceed 50 characters")
	}

	// Allow only letters, spaces, hyphens, and apostrophes
	nameRegex := regexp.MustCompile(`^[a-zA-Z\s\-']+$`)
	if !nameRegex.MatchString(name) {
		return errors.NewValidationError(fieldName + " can only contain letters, spaces, hyphens, and apostrophes")
	}

	return nil
}

func ValidateURL(url, fieldName string) *errors.AppError {
	if url == "" {
		return nil // Optional field
	}

	urlRegex := regexp.MustCompile(`^https?://[^\s]+$`)
	if !urlRegex.MatchString(url) {
		return errors.NewValidationError(fieldName + " must be a valid URL")
	}

	return nil
}

// Validation result aggregator
type ValidationResult struct {
	Errors []string `json:"errors,omitempty"`
}

func (vr *ValidationResult) AddError(err *errors.AppError) {
	if err != nil {
		vr.Errors = append(vr.Errors, err.Message)
	}
}

func (vr *ValidationResult) HasErrors() bool {
	return len(vr.Errors) > 0
}

func (vr *ValidationResult) ToAppError() *errors.AppError {
	if !vr.HasErrors() {
		return nil
	}

	return &errors.AppError{
		Type:       errors.ErrorTypeValidation,
		Message:    "validation failed",
		Details:    strings.Join(vr.Errors, "; "),
		StatusCode: 400,
	}
}
