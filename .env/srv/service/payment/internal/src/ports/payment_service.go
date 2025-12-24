// internal/core/ports/payment_service.go
package ports

import (
	"context"
	"payment-service/internal/core/domain"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type CreatePaymentRequest struct {
	ClientID    string                 `json:"client_id" validate:"required"`
	MerchantID  string                 `json:"merchant_id" validate:"required"`
	OrderID     string                 `json:"order_id" validate:"required"`
	Amount      decimal.Decimal        `json:"amount" validate:"required,gt=0"`
	Currency    domain.Currency        `json:"currency" validate:"required"`
	Method      domain.PaymentMethod   `json:"method" validate:"required"`
	Description string                 `json:"description" validate:"required,max=500"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

type ProcessPaymentRequest struct {
	PaymentID      uuid.UUID              `json:"payment_id" validate:"required"`
	PaymentDetails map[string]interface{} `json:"payment_details" validate:"required"`
}

type RefundPaymentRequest struct {
	PaymentID uuid.UUID       `json:"payment_id" validate:"required"`
	Amount    decimal.Decimal `json:"amount" validate:"required,gt=0"`
	Reason    string          `json:"reason" validate:"required,max=500"`
}

type PaymentService interface {
	CreatePayment(ctx context.Context, req CreatePaymentRequest) (*domain.Payment, error)
	ProcessPayment(ctx context.Context, req ProcessPaymentRequest) (*domain.Payment, error)
	RefundPayment(ctx context.Context, req RefundPaymentRequest) (*domain.Payment, error)
	GetPayment(ctx context.Context, paymentID uuid.UUID) (*domain.Payment, error)
	GetPaymentByOrderID(ctx context.Context, clientID, orderID string) (*domain.Payment, error)
	ListPayments(ctx context.Context, clientID string, limit, offset int) ([]*domain.Payment, error)
	CancelPayment(ctx context.Context, paymentID uuid.UUID) error
}
