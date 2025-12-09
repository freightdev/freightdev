// pkg/errors/auth.go
package errors

import (
	"fmt"
	"net/http"
)

// ErrorCode represents an error code
type ErrorCode string

const (
	// Authentication errors
	ErrCodeInvalidCredentials ErrorCode = "INVALID_CREDENTIALS"
	ErrCodeUserNotFound       ErrorCode = "USER_NOT_FOUND"
	ErrCodeUserAlreadyExists  ErrorCode = "USER_ALREADY_EXISTS"
	ErrCodeInvalidToken       ErrorCode = "INVALID_TOKEN"
	ErrCodeTokenExpired       ErrorCode = "TOKEN_EXPIRED"
	ErrCodeSessionExpired     ErrorCode = "SESSION_EXPIRED"
	ErrCodeUnauthorized       ErrorCode = "UNAUTHORIZED"
	ErrCodeForbidden          ErrorCode = "FORBIDDEN"

	// Validation errors
	ErrCodeInvalidInput     ErrorCode = "INVALID_INPUT"
	ErrCodeValidationFailed ErrorCode = "VALIDATION_FAILED"

	// System errors
	ErrCodeInternalServer     ErrorCode = "INTERNAL_SERVER_ERROR"
	ErrCodeDatabaseError      ErrorCode = "DATABASE_ERROR"
	ErrCodeServiceUnavailable ErrorCode = "SERVICE_UNAVAILABLE"
)

// AppError represents an application error
type AppError struct {
	Code       ErrorCode `json:"code"`
	Message    string    `json:"message"`
	Details    string    `json:"details,omitempty"`
	HTTPStatus int       `json:"-"`
}

// Error implements the error interface
func (e *AppError) Error() string {
	if e.Details != "" {
		return fmt.Sprintf("%s: %s (%s)", e.Code, e.Message, e.Details)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// NewAppError creates a new application error
func NewAppError(code ErrorCode, message string, httpStatus int) *AppError {
	return &AppError{
		Code:       code,
		Message:    message,
		HTTPStatus: httpStatus,
	}
}

// NewAppErrorWithDetails creates a new application error with details
func NewAppErrorWithDetails(code ErrorCode, message, details string, httpStatus int) *AppError {
	return &AppError{
		Code:       code,
		Message:    message,
		Details:    details,
		HTTPStatus: httpStatus,
	}
}

// Common error constructors
func ErrInvalidCredentials() *AppError {
	return NewAppError(ErrCodeInvalidCredentials, "Invalid email or password", http.StatusUnauthorized)
}

func ErrUserNotFound() *AppError {
	return NewAppError(ErrCodeUserNotFound, "User not found", http.StatusNotFound)
}

func ErrUserAlreadyExists() *AppError {
	return NewAppError(ErrCodeUserAlreadyExists, "User already exists", http.StatusConflict)
}

func ErrInvalidToken() *AppError {
	return NewAppError(ErrCodeInvalidToken, "Invalid or malformed token", http.StatusUnauthorized)
}

func ErrTokenExpired() *AppError {
	return NewAppError(ErrCodeTokenExpired, "Token has expired", http.StatusUnauthorized)
}

func ErrUnauthorized() *AppError {
	return NewAppError(ErrCodeUnauthorized, "Access denied", http.StatusUnauthorized)
}

func ErrForbidden() *AppError {
	return NewAppError(ErrCodeForbidden, "Insufficient permissions", http.StatusForbidden)
}

func ErrValidationFailed(details string) *AppError {
	return NewAppErrorWithDetails(ErrCodeValidationFailed, "Validation failed", details, http.StatusBadRequest)
}

func ErrInternalServer() *AppError {
	return NewAppError(ErrCodeInternalServer, "Internal server error", http.StatusInternalServerError)
}

func ErrDatabaseError(details string) *AppError {
	return NewAppErrorWithDetails(ErrCodeDatabaseError, "Database operation failed", details, http.StatusInternalServerError)
}
