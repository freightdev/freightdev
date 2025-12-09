// internal/core/ports/payment_processor.go
package ports

import (
	"context"
	"payment-service/internal/core/domain"

	"github.com/shopspring/decimal"
)

type ProcessPaymentRequest struct {
	Amount         decimal.Decimal        `json:"amount"`
	Currency       domain.Currency        `json:"currency"`
	Method         domain.PaymentMethod   `json:"method"`
	PaymentDetails map[string]interface{} `json:"payment_details"`
	Metadata       map[string]interface{} `json:"metadata,omitempty"`
}

type ProcessPaymentResponse struct {
	ProcessorRef string                 `json:"processor_ref"`
	Status       domain.PaymentStatus   `json:"status"`
	Metadata     map[string]interface{} `json:"metadata,omitempty"`
}

type RefundRequest struct {
	ProcessorRef string          `json:"processor_ref"`
	Amount       decimal.Decimal `json:"amount"`
	Currency     domain.Currency `json:"currency"`
	Reason       string          `json:"reason"`
}

type RefundResponse struct {
	RefundRef string                 `json:"refund_ref"`
	Status    domain.PaymentStatus   `json:"status"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

type PaymentProcessor interface {
	ProcessPayment(ctx context.Context, req ProcessPaymentRequest) (*ProcessPaymentResponse, error)
	RefundPayment(ctx context.Context, req RefundRequest) (*RefundResponse, error)
	GetPaymentStatus(ctx context.Context, processorRef string) (domain.PaymentStatus, error)
	SupportsMethod(method domain.PaymentMethod) bool
	SupportsCurrency(currency domain.Currency) bool
}
