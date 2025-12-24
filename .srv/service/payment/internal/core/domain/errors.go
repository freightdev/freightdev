// internal/core/domain/errors.go
package domain

import "fmt"

type DomainError struct {
	Type    string
	Message string
	Code    string
}

func (e DomainError) Error() string {
	return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

var (
	ErrPaymentNotFound = DomainError{
		Type:    "NotFound",
		Code:    "PAYMENT_NOT_FOUND",
		Message: "payment not found",
	}

	ErrPaymentAlreadyProcessed = DomainError{
		Type:    "Conflict",
		Code:    "PAYMENT_ALREADY_PROCESSED",
		Message: "payment has already been processed",
	}

	ErrInvalidAmount = DomainError{
		Type:    "ValidationError",
		Code:    "INVALID_AMOUNT",
		Message: "payment amount must be greater than zero",
	}

	ErrUnsupportedCurrency = DomainError{
		Type:    "ValidationError",
		Code:    "UNSUPPORTED_CURRENCY",
		Message: "currency not supported",
	}

	ErrUnsupportedPaymentMethod = DomainError{
		Type:    "ValidationError",
		Code:    "UNSUPPORTED_PAYMENT_METHOD",
		Message: "payment method not supported",
	}

	ErrInsufficientFunds = DomainError{
		Type:    "ProcessingError",
		Code:    "INSUFFICIENT_FUNDS",
		Message: "insufficient funds for transaction",
	}

	ErrProcessorUnavailable = DomainError{
		Type:    "ServiceError",
		Code:    "PROCESSOR_UNAVAILABLE",
		Message: "payment processor temporarily unavailable",
	}
)
