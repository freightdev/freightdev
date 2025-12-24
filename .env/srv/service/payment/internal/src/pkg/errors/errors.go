// pkg/errors/errors.go
package errors

import (
	"fmt"
	"net/http"
)

type ErrorType string

const (
	ErrorTypeValidation   ErrorType = "validation_error"
	ErrorTypeNotFound     ErrorType = "not_found"
	ErrorTypeConflict     ErrorType = "conflict"
	ErrorTypeUnauthorized ErrorType = "unauthorized"
	ErrorTypeForbidden    ErrorType = "forbidden"
	ErrorTypeInternal     ErrorType = "internal_error"
	ErrorTypeExternal     ErrorType = "external_error"
	ErrorTypeBadRequest   ErrorType = "bad_request"
)

type AppError struct {
	Type       ErrorType              `json:"type"`
	Code       string                 `json:"code"`
	Message    string                 `json:"message"`
	Details    map[string]interface{} `json:"details,omitempty"`
	HTTPStatus int                    `json:"-"`
	Err        error                  `json:"-"`
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("[%s] %s: %v", e.Code, e.Message, e.Err)
	}
	return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

func (e *AppError) Unwrap() error {
	return e.Err
}

func NewValidationError(code, message string, details map[string]interface{}) *AppError {
	return &AppError{
		Type:       ErrorTypeValidation,
		Code:       code,
		Message:    message,
		Details:    details,
		HTTPStatus: http.StatusBadRequest,
	}
}

func NewNotFoundError(code, message string) *AppError {
	return &AppError{
		Type:       ErrorTypeNotFound,
		Code:       code,
		Message:    message,
		HTTPStatus: http.StatusNotFound,
	}
}

func NewConflictError(code, message string) *AppError {
	return &AppError{
		Type:       ErrorTypeConflict,
		Code:       code,
		Message:    message,
		HTTPStatus: http.StatusConflict,
	}
}

func NewUnauthorizedError(code, message string) *AppError {
	return &AppError{
		Type:       ErrorTypeUnauthorized,
		Code:       code,
		Message:    message,
		HTTPStatus: http.StatusUnauthorized,
	}
}

func NewInternalError(code, message string, err error) *AppError {
	return &AppError{
		Type:       ErrorTypeInternal,
		Code:       code,
		Message:    message,
		HTTPStatus: http.StatusInternalServerError,
		Err:        err,
	}
}

func NewExternalError(code, message string, err error) *AppError {
	return &AppError{
		Type:       ErrorTypeExternal,
		Code:       code,
		Message:    message,
		HTTPStatus: http.StatusBadGateway,
		Err:        err,
	}
}
