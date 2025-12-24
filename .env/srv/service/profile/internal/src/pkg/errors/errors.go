// internal/shared/errors/errors.go
package errors

import (
	"errors"
	"fmt"
	"net/http"
)

type ErrorType string

const (
	ErrorTypeValidation         ErrorType = "VALIDATION_ERROR"
	ErrorTypeNotFound           ErrorType = "NOT_FOUND"
	ErrorTypeConflict           ErrorType = "CONFLICT"
	ErrorTypeUnauthorized       ErrorType = "UNAUTHORIZED"
	ErrorTypeForbidden          ErrorType = "FORBIDDEN"
	ErrorTypeInternal           ErrorType = "INTERNAL_ERROR"
	ErrorTypeRateLimit          ErrorType = "RATE_LIMIT"
	ErrorTypeBadRequest         ErrorType = "BAD_REQUEST"
	ErrorTypeServiceUnavailable ErrorType = "SERVICE_UNAVAILABLE"
)

type AppError struct {
	Type       ErrorType `json:"type"`
	Message    string    `json:"message"`
	Details    string    `json:"details,omitempty"`
	StatusCode int       `json:"-"`
	Cause      error     `json:"-"`
}

func (e *AppError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("%s: %s (caused by: %v)", e.Type, e.Message, e.Cause)
	}
	return fmt.Sprintf("%s: %s", e.Type, e.Message)
}

func (e *AppError) Unwrap() error {
	return e.Cause
}

func NewValidationError(message string) *AppError {
	return &AppError{
		Type:       ErrorTypeValidation,
		Message:    message,
		StatusCode: http.StatusBadRequest,
	}
}

func NewNotFoundError(resource string) *AppError {
	return &AppError{
		Type:       ErrorTypeNotFound,
		Message:    fmt.Sprintf("%s not found", resource),
		StatusCode: http.StatusNotFound,
	}
}

func NewConflictError(message string) *AppError {
	return &AppError{
		Type:       ErrorTypeConflict,
		Message:    message,
		StatusCode: http.StatusConflict,
	}
}

func NewUnauthorizedError(message string) *AppError {
	return &AppError{
		Type:       ErrorTypeUnauthorized,
		Message:    message,
		StatusCode: http.StatusUnauthorized,
	}
}

func NewInternalError(message string, cause error) *AppError {
	return &AppError{
		Type:       ErrorTypeInternal,
		Message:    message,
		StatusCode: http.StatusInternalServerError,
		Cause:      cause,
	}
}

func WrapError(err error, message string) *AppError {
	if err == nil {
		return nil
	}

	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr
	}

	return NewInternalError(message, err)
}
