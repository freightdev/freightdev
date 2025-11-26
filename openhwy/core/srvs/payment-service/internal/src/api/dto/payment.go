// internal/adapters/http/dto/payment.go
package dto

import (
	"payment-service/internal/core/domain"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// Request DTOs
type CreatePaymentRequest struct {
	ClientID    string                 `json:"client_id" validate:"required,max=255"`
	MerchantID  string                 `json:"merchant_id" validate:"required,max=255"`
	OrderID     string                 `json:"order_id" validate:"required,max=255"`
	Amount      decimal.Decimal        `json:"amount" validate:"required,decimal_gt=0"`
	Currency    domain.Currency        `json:"currency" validate:"required,currency"`
	Method      domain.PaymentMethod   `json:"method" validate:"required,payment_method"`
	Description string                 `json:"description" validate:"required,max=500"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

type ProcessPaymentRequest struct {
	PaymentDetails map[string]interface{} `json:"payment_details" validate:"required"`
}

type RefundPaymentRequest struct {
	Amount decimal.Decimal `json:"amount" validate:"required,decimal_gt=0"`
	Reason string          `json:"reason" validate:"required,max=500"`
}

// Response DTOs
type PaymentResponse struct {
	ID            uuid.UUID              `json:"id"`
	ClientID      string                 `json:"client_id"`
	MerchantID    string                 `json:"merchant_id"`
	OrderID       string                 `json:"order_id"`
	Amount        decimal.Decimal        `json:"amount"`
	Currency      domain.Currency        `json:"currency"`
	Status        domain.PaymentStatus   `json:"status"`
	Method        domain.PaymentMethod   `json:"method"`
	Description   string                 `json:"description"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
	ProcessorRef  string                 `json:"processor_ref,omitempty"`
	FailureReason string                 `json:"failure_reason,omitempty"`
	CreatedAt     time.Time              `json:"created_at"`
	UpdatedAt     time.Time              `json:"updated_at"`
	ProcessedAt   *time.Time             `json:"processed_at,omitempty"`
}

type PaymentListResponse struct {
	Payments   []PaymentResponse `json:"payments"`
	TotalCount int               `json:"total_count"`
	Limit      int               `json:"limit"`
	Offset     int               `json:"offset"`
}

type ErrorResponse struct {
	Type      string                 `json:"type"`
	Code      string                 `json:"code"`
	Message   string                 `json:"message"`
	Details   map[string]interface{} `json:"details,omitempty"`
	RequestID string                 `json:"request_id"`
	Timestamp time.Time              `json:"timestamp"`
}

type HealthResponse struct {
	Status    string            `json:"status"`
	Version   string            `json:"version"`
	Timestamp time.Time         `json:"timestamp"`
	Services  map[string]string `json:"services"`
}

// Conversion functions
func ToPaymentResponse(payment *domain.Payment) *PaymentResponse {
	return &PaymentResponse{
		ID:            payment.ID,
		ClientID:      payment.ClientID,
		MerchantID:    payment.MerchantID,
		OrderID:       payment.OrderID,
		Amount:        payment.Amount,
		Currency:      payment.Currency,
		Status:        payment.Status,
		Method:        payment.Method,
		Description:   payment.Description,
		Metadata:      payment.Metadata,
		ProcessorRef:  payment.ProcessorRef,
		FailureReason: payment.FailureReason,
		CreatedAt:     payment.CreatedAt,
		UpdatedAt:     payment.UpdatedAt,
		ProcessedAt:   payment.ProcessedAt,
	}
}

func ToPaymentListResponse(payments []*domain.Payment, totalCount, limit, offset int) *PaymentListResponse {
	responses := make([]PaymentResponse, len(payments))
	for i, payment := range payments {
		responses[i] = *ToPaymentResponse(payment)
	}

	return &PaymentListResponse{
		Payments:   responses,
		TotalCount: totalCount,
		Limit:      limit,
		Offset:     offset,
	}
}
